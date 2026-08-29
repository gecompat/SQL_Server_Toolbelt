#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <run-script> [args...]" >&2
    exit 64
fi

run_script="$1"
shift

if [[ ! -f "${run_script}" ]]; then
    echo "Testskript wurde nicht gefunden." >&2
    exit 66
fi

run_script_path="$(readlink -f "${run_script}")"

# GitHub Actions und andere disposable Runner verwenden weiterhin den
# unveränderten Containerpfad. Nur der bereits validierte lokale Orchestrator
# setzt TBX_SQL_TARGET=lab und aktiviert damit diesen Adapter.
if [[ "${TBX_SQL_TARGET:-runner}" != "lab" ]]; then
    exec bash "${run_script_path}" "$@"
fi

required_variables=(
    TBX_SQL_HOST
    TBX_SQL_PORT
    TBX_SQL_USER
    TBX_SQL_PASSWORD
    TBX_SQL_DATABASE
    TBX_SQL_KEY
    TBX_SQL_VERSION
    TBX_SQL_PATCH
    TBX_TEST_DB_SUFFIX
    TBX_TEST_SQLCMD_BIN
)

for variable_name in "${required_variables[@]}"; do
    if [[ -z "${!variable_name:-}" ]]; then
        echo "Erforderliche Lab-Prozessvariable fehlt: ${variable_name}" >&2
        exit 65
    fi
done

if [[ ! "${TBX_TEST_DB_SUFFIX}" =~ ^[a-f0-9]{12}$ ]]; then
    echo "TBX_TEST_DB_SUFFIX hat nicht das erwartete Format." >&2
    exit 65
fi

if [[ "${TBX_SQL_ENCRYPT:-}" != "True" || "${TBX_SQL_TRUST_SERVER_CERTIFICATE:-}" != "True" ]]; then
    echo "Der Lab-Vertrag verlangt Encrypt=True und TrustServerCertificate=True." >&2
    exit 65
fi

repo_root="$(git -C "$(dirname "${run_script_path}")" rev-parse --show-toplevel)"
lab_sqlcmd="${TBX_TEST_SQLCMD_BIN}"

if command -v cygpath >/dev/null 2>&1; then
    lab_sqlcmd="$(cygpath -u "${lab_sqlcmd}")"
fi

if [[ ! -f "${lab_sqlcmd}" && ! -x "${lab_sqlcmd}" ]]; then
    echo "Der ausgewählte lokale sqlcmd-Client ist nicht aufrufbar." >&2
    exit 69
fi

export SQLCMDPASSWORD="${TBX_SQL_PASSWORD}"
base_sqlcmd_args=(
    -S "tcp:${TBX_SQL_HOST},${TBX_SQL_PORT}"
    -U "${TBX_SQL_USER}"
    -d "${TBX_SQL_DATABASE}"
    -N
    -C
    -b
    -l 15
    -t 120
)

run_control_query() {
    local query="$1"
    shift
    "${lab_sqlcmd}" "${base_sqlcmd_args[@]}" "$@" -Q "${query}"
}

# Die zufällige Testlauf-ID muss vor der ersten Mutation eindeutig sein. Damit
# können beim Cleanup ausschließlich Datenbanken dieses Laufs adressiert werden.
run_control_query "
IF EXISTS
   (
       SELECT 1
       FROM sys.databases
       WHERE name LIKE N'%[_]${TBX_TEST_DB_SUFFIX}'
   )
    THROW 51000, N'Die Testlauf-ID kollidiert mit einer vorhandenen Datenbank.', 1;
" >/dev/null

zip_clr_before=""
zip_show_advanced_before=""
zip_trust_before=""

if [[ "$(basename "${run_script_path}")" == "run-zip-memory-linux.sh" ]]; then
    if [[ -z "${TBX_ZIP_ASSEMBLY_HASH:-}" ]]; then
        echo "TBX_ZIP_ASSEMBLY_HASH fehlt für den ZIP-Memory-Lauf." >&2
        exit 65
    fi

    zip_clr_before="$(run_control_query "SET NOCOUNT ON; SELECT CONVERT(int, value_in_use) FROM sys.configurations WHERE name = N'clr enabled';" -h -1 -W 2>/dev/null | tr -d '[:space:]')"
    zip_show_advanced_before="$(run_control_query "SET NOCOUNT ON; SELECT CONVERT(int, value_in_use) FROM sys.configurations WHERE name = N'show advanced options';" -h -1 -W 2>/dev/null | tr -d '[:space:]')"
    zip_trust_before="$(run_control_query "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.trusted_assemblies WHERE hash = CONVERT(varbinary(64), N'${TBX_ZIP_ASSEMBLY_HASH}', 1);" -h -1 -W 2>/dev/null | tr -d '[:space:]')"
fi

lab_work_dir="$(mktemp -d)"
shim_path="${lab_work_dir}/docker"

cleanup_lab_run() {
    local exit_code=$?
    set +e

    run_control_query "
DECLARE @Sql nvarchar(max) = N'';
SELECT @Sql +=
       N'ALTER DATABASE ' + QUOTENAME(name)
       + N' SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE '
       + QUOTENAME(name) + N';'
FROM sys.databases
WHERE name LIKE N'%[_]${TBX_TEST_DB_SUFFIX}';
IF @Sql <> N''
    EXEC sys.sp_executesql @Sql;

DECLARE @LinkedServer sysname = N'TBX_LOOPBACK_${TBX_TEST_DB_SUFFIX}';
IF EXISTS (SELECT 1 FROM sys.servers WHERE name = @LinkedServer)
    EXEC master.dbo.sp_dropserver
         @server = @LinkedServer,
         @droplogins = N'droplogins';
" >/dev/null 2>&1

    if [[ "$(basename "${run_script_path}")" == "run-zip-memory-linux.sh" ]]; then
        if [[ "${zip_trust_before}" == "0" ]]; then
            run_control_query "
IF EXISTS
   (
       SELECT 1
       FROM sys.trusted_assemblies
       WHERE hash = CONVERT(varbinary(64), N'${TBX_ZIP_ASSEMBLY_HASH}', 1)
   )
    EXEC sys.sp_drop_trusted_assembly
         @hash = CONVERT(varbinary(64), N'${TBX_ZIP_ASSEMBLY_HASH}', 1);
" >/dev/null 2>&1
        fi

        if [[ "${zip_clr_before}" == "0" ]]; then
            run_control_query "
EXEC sys.sp_configure N'clr enabled', 0;
RECONFIGURE;
" >/dev/null 2>&1
        fi

        if [[ "${zip_show_advanced_before}" == "0" ]]; then
            run_control_query "
EXEC sys.sp_configure N'show advanced options', 0;
RECONFIGURE;
" >/dev/null 2>&1
        fi
    fi

    rm -rf "${lab_work_dir}"
    unset SQLCMDPASSWORD
    exit "${exit_code}"
}

trap cleanup_lab_run EXIT INT TERM

cat > "${shim_path}" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

lab_sqlcmd="${TBX_TEST_SQLCMD_BIN:?TBX_TEST_SQLCMD_BIN fehlt}"
if command -v cygpath >/dev/null 2>&1; then
    lab_sqlcmd="$(cygpath -u "${lab_sqlcmd}")"
fi

lab_workspace="${TBX_LAB_WORKSPACE_ROOT:?TBX_LAB_WORKSPACE_ROOT fehlt}"
test_suffix="${TBX_TEST_DB_SUFFIX:?TBX_TEST_DB_SUFFIX fehlt}"
export SQLCMDPASSWORD="${TBX_SQL_PASSWORD:?TBX_SQL_PASSWORD fehlt}"

map_workspace_path() {
    local value="$1"

    if [[ "${value}" == "/workspace" ]]; then
        printf '%s\n' "${lab_workspace}"
        return
    fi

    if [[ "${value}" == /workspace/* ]]; then
        printf '%s/%s\n' "${lab_workspace}" "${value#/workspace/}"
        return
    fi

    printf '%s\n' "${value}"
}

map_sqlcmd_file_path() {
    local value
    value="$(map_workspace_path "$1")"
    if command -v cygpath >/dev/null 2>&1; then
        cygpath -w "${value}"
        return
    fi
    printf '%s\n' "${value}"
}

rewrite_test_database_names() {
    local value="$1"
    printf '%s\n' "${value}" |
        sed -E \
            -e "s/(tbx_[A-Za-z0-9_]+)/\\1_${test_suffix}/g" \
            -e "s/TBX_LOOPBACK/TBX_LOOPBACK_${test_suffix}/g"
}

run_sqlcmd() {
    local workdir="$1"
    shift

    local -a parsed=(
        -S "tcp:${TBX_SQL_HOST},${TBX_SQL_PORT}"
        -U "${TBX_SQL_USER}"
        -N
        -C
        -b
        -l 15
        -t 120
        -f 65001
        -r 1
        -j
    )
    local stdin_file=""
    local sqlcmd_variable_mode="0"

    while (( $# )); do
        case "$1" in
            -S|-U|-P)
                sqlcmd_variable_mode="0"
                shift 2
                ;;
            -d)
                sqlcmd_variable_mode="0"
                parsed+=("-d" "$(rewrite_test_database_names "$2")")
                shift 2
                ;;
            -Q)
                sqlcmd_variable_mode="0"
                parsed+=("-Q" "$(rewrite_test_database_names "$2")")
                shift 2
                ;;
            -i)
                sqlcmd_variable_mode="0"
                if [[ "$2" == "/dev/stdin" ]]; then
                    stdin_file="$(mktemp)"
                    cat > "${stdin_file}"
                    parsed+=("-i" "$(map_sqlcmd_file_path "${stdin_file}")")
                else
                    parsed+=("-i" "$(map_sqlcmd_file_path "$2")")
                fi
                shift 2
                ;;
            -v)
                sqlcmd_variable_mode="1"
                shift
                ;;
            SaPassword=*)
                export SaPassword="${TBX_SQL_PASSWORD}"
                shift
                ;;
            *)
                if [[ "${sqlcmd_variable_mode}" == "1" && "$1" == *=* ]]; then
                    variable_name="${1%%=*}"
                    variable_value="${1#*=}"
                    if [[ ! "${variable_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                        echo "Ungültiger SQLCMD-Variablenname im Lab-Adapter." >&2
                        return 64
                    fi
                    variable_value="$(rewrite_test_database_names \
                        "$(map_workspace_path "${variable_value}")")"
                    export "${variable_name}=${variable_value}"
                else
                    rewritten_value="$(rewrite_test_database_names \
                        "$(map_workspace_path "$1")")"
                    parsed+=("${rewritten_value}")
                fi
                shift
                ;;
        esac
    done

    if [[ -n "${workdir}" ]]; then
        set +e
        (cd "${workdir}" && "${lab_sqlcmd}" "${parsed[@]}")
        command_status=$?
        set -e
    else
        set +e
        "${lab_sqlcmd}" "${parsed[@]}"
        command_status=$?
        set -e
    fi

    if [[ -n "${stdin_file}" ]]; then
        rm -f "${stdin_file}"
    fi

    if [[ "${command_status}" -ne 0 ]]; then
        echo "LAB_SQLCMD_EXIT=${command_status}" >&2
    fi

    return "${command_status}"
}

case "${1:-}" in
    run|rm|logs)
        exit 0
        ;;
    exec)
        shift
        workdir=""

        while (( $# )); do
            case "$1" in
                --workdir=*)
                    workdir="$(map_workspace_path "${1#*=}")"
                    shift
                    ;;
                --workdir)
                    workdir="$(map_workspace_path "$2")"
                    shift 2
                    ;;
                -i|-it|-t)
                    shift
                    ;;
                -e|--env|-u|--user)
                    shift 2
                    ;;
                --*)
                    shift
                    ;;
                *)
                    break
                    ;;
            esac
        done

        [[ $# -gt 0 ]] || exit 64
        shift
        [[ $# -gt 0 ]] || exit 64

        command_path="$1"
        shift

        case "${command_path}" in
            /opt/mssql-tools18/bin/sqlcmd|/opt/mssql-tools/bin/sqlcmd|sqlcmd)
                run_sqlcmd "${workdir}" "$@"
                ;;
            test)
                if [[ "${1:-}" == "-x" ]]; then
                    exit 0
                fi
                command test "$@"
                ;;
            *)
                command_path="$(map_workspace_path "${command_path}")"
                if [[ -n "${workdir}" ]]; then
                    (cd "${workdir}" && "${command_path}" "$@")
                else
                    "${command_path}" "$@"
                fi
                ;;
        esac
        ;;
    *)
        echo "Nicht unterstützter docker-Aufruf im lokalen Lab-Adapter." >&2
        exit 64
        ;;
esac
EOF

chmod +x "${shim_path}"

export TBX_LAB_WORKSPACE_ROOT="${repo_root}"
export PATH="${lab_work_dir}:${PATH}"

bash "${run_script_path}" "$@"
