#!/usr/bin/env bash

set -euo pipefail

# Ausschließlich flüchtige Runner-Container und synthetische Testdatenbanken.
# Der lokale SQL_Server_Lab-Vertrag bleibt beim separaten Labtreiber.
if [[ "${TBX_SQL_TARGET:-runner}" == lab ]]; then
    echo "JSON_POINTER_DEDICATED_LAB_DRIVER_REQUIRED" >&2
    exit 65
fi

sql_version="${TBX_SQL_VERSION:?TBX_SQL_VERSION fehlt}"
case "${sql_version}" in
    2019) compatibility_levels="150" ;;
    2022) compatibility_levels="150 160" ;;
    2025) compatibility_levels="150 160 170" ;;
    *) echo "JSON_POINTER_CI_UNSUPPORTED_SQL_VERSION" >&2; exit 65 ;;
esac
sql_image="${TBX_SQL_IMAGE:?TBX_SQL_IMAGE fehlt}"
if [[ "${sql_image}" != "mcr.microsoft.com/mssql/server:${sql_version}-latest" ]]; then
    echo "JSON_POINTER_CI_IMAGE_MISMATCH" >&2
    exit 65
fi

container_name="tbx-json-pointer-${GITHUB_RUN_ID:-$$}-${GITHUB_RUN_ATTEMPT:-1}-${sql_version}"
workspace="${GITHUB_WORKSPACE:-$(pwd)}"
private_dir="$(mktemp -d)"
sa_password="Tbx!$(openssl rand -hex 16)Aa1"
echo "::add-mask::${sa_password}"

cleanup() {
    docker rm -f "${container_name}" >/dev/null 2>&1 || true
    if [[ -n "${private_dir}" && -d "${private_dir}" ]]; then
        rm -rf -- "${private_dir}"
    fi
}
trap cleanup EXIT

run_private() {
    local label="$1"
    shift
    if ! "$@" >"${private_dir}/last-output" 2>&1; then
        echo "JSON_POINTER_CI_STEP_FAILED:${label}" >&2
        return 1
    fi
}

run_private start_container docker run --detach \
    --name "${container_name}" \
    --publish 127.0.0.1::1433 \
    --env ACCEPT_EULA=Y \
    --env MSSQL_PID=Developer \
    --env MSSQL_SA_PASSWORD="${sa_password}" \
    --volume "${workspace}:/workspace:ro" \
    "${sql_image}"

sqlcmd_path=""
for candidate in /opt/mssql-tools18/bin/sqlcmd /opt/mssql-tools/bin/sqlcmd; do
    if docker exec "${container_name}" test -x "${candidate}" >/dev/null 2>&1; then
        sqlcmd_path="${candidate}"
        break
    fi
done
if [[ -z "${sqlcmd_path}" ]]; then
    echo "JSON_POINTER_CI_SQLCMD_UNAVAILABLE" >&2
    exit 1
fi

ready=false
for _ in $(seq 1 60); do
    if docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 5 \
        -Q 'SELECT 1;' >"${private_dir}/last-output" 2>&1; then
        ready=true
        break
    fi
    sleep 2
done
if [[ "${ready}" != true ]]; then
    echo "JSON_POINTER_CI_SQL_NOT_READY" >&2
    exit 1
fi

published="$(docker port "${container_name}" 1433/tcp)"
port="${published##*:}"
if [[ "${published}" != 127.0.0.1:* || ! "${port}" =~ ^[0-9]{1,5}$ ]]; then
    echo "JSON_POINTER_CI_LOCAL_PORT_INVALID" >&2
    exit 1
fi
export TBX_CI_SQL_PORT="${port}"
export TBX_CI_SQL_PASSWORD="${sa_password}"

run_query() {
    local label="$1" database="$2" query="$3"
    run_private "${label}" docker exec "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -Q "${query}"
}

run_file() {
    local label="$1" database="$2" directory="$3" filename="$4"
    shift 4
    run_private "${label}" docker exec --workdir "${directory}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${filename}" "$@"
}

expect_central_confirm0_rejection() {
    local database="$1"
    # Die erwartete SQL-Ausnahme bleibt privat; nur Nummer und State sind Orakel.
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i Uninstall.sql -v ConfirmNoExternalConsumers=0 \
        >"${private_dir}/last-output" 2>&1; then
        echo "JSON_POINTER_CI_CONFIRM0_UNEXPECTED_SUCCESS" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55526, Level 16, State 1,' "${private_dir}/last-output"; then
        echo "JSON_POINTER_CI_CONFIRM0_WRONG_ERROR" >&2
        return 1
    fi
}

expect_dependency_rejection() {
    local label="$1" database="$2" script="$3"
    shift 3
    # Der synthetische View-Verbraucher muss Deploy und Uninstall blockieren.
    if docker exec --workdir "${deployment}" \
        "${container_name}" "${sqlcmd_path}" \
        -S localhost -U sa -P "${sa_password}" -C -b -l 15 -t 180 \
        -d "${database}" -i "${script}" "$@" \
        >"${private_dir}/last-output" 2>&1; then
        echo "JSON_POINTER_CI_DEPENDENCY_UNEXPECTED_SUCCESS:${label}" >&2
        return 1
    fi
    if ! grep -Eq '^Msg 55525, Level 16, State 3,' "${private_dir}/last-output"; then
        echo "JSON_POINTER_CI_DEPENDENCY_WRONG_ERROR:${label}" >&2
        return 1
    fi
}

deployment="/workspace/Modules/toolbelt.json.pointer/Deployment"
runtime="/workspace/Modules/toolbelt.json.pointer/Tests/Runtime"
client="${workspace}/Tests/CI/run-json-pointer-client.ps1"

for level in ${compatibility_levels}; do
    local_db="tbx_json_pointer_local_${level}"
    central_db="tbx_json_pointer_central_${level}"
    consumer_db="tbx_json_pointer_consumer_${level}"
    run_query create_local master "CREATE DATABASE [${local_db}] COLLATE Latin1_General_100_CS_AS;"
    run_query create_central master "CREATE DATABASE [${central_db}] COLLATE Latin1_General_100_BIN2;"
    run_query create_consumer master "CREATE DATABASE [${consumer_db}] COLLATE Latin1_General_100_CI_AS_SC_UTF8;"
    for database in "${local_db}" "${central_db}" "${consumer_db}"; do
        run_query compatibility master "ALTER DATABASE [${database}] SET COMPATIBILITY_LEVEL=${level};"
    done

    run_file deploy_local "${local_db}" "${deployment}" Deploy.sql -v DeploymentMode=local
    run_file deploy_central "${central_db}" "${deployment}" Deploy.sql -v DeploymentMode=central
    run_file baseline_local "${local_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${local_db}"
    run_file baseline_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"

    for mode in local central consumer; do
        case "${mode}" in
            local) database="${local_db}"; provider="${local_db}" ;;
            central) database="${central_db}"; provider="${central_db}" ;;
            consumer) database="${consumer_db}"; provider="${central_db}" ;;
        esac
        run_file "contract_${mode}" "${database}" "${runtime}" Contract.Tests.sql -v "ToolbeltDatabase=${provider}"
        run_file "safety_${mode}" "${database}" "${runtime}" Safety.Tests.sql -v "ToolbeltDatabase=${provider}"
        run_private "client_${mode}" pwsh -NoProfile -File "${client}" -Database "${database}" -ToolbeltDatabase "${provider}"
    done

    run_file repeat_local "${local_db}" "${deployment}" Deploy.sql -v DeploymentMode=local
    run_file repeat_central "${central_db}" "${deployment}" Deploy.sql -v DeploymentMode=central
    run_file repeat_baseline_local "${local_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${local_db}"
    run_file repeat_baseline_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_query create_dependency "${central_db}" "EXEC(N'CREATE VIEW dbo.VW_PointerDependencyCI AS SELECT Status FROM toolbelt_json.TVF_ResolveJsonPointer(N''{}'',N'''',DEFAULT,DEFAULT);'); IF NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.VW_PointerDependencyCI',N'V') AND referenced_id=OBJECT_ID(N'toolbelt_json.TVF_ResolveJsonPointer',N'TF')) THROW 55592,N'Pointer: synthetische Abhängigkeit fehlt.',9;"
    expect_dependency_rejection deploy "${central_db}" Deploy.sql -v DeploymentMode=central
    run_file dependency_deploy_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    expect_dependency_rejection uninstall "${central_db}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_file dependency_uninstall_preserved "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_query drop_dependency "${central_db}" "IF NOT EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referencing_id=OBJECT_ID(N'dbo.VW_PointerDependencyCI',N'V') AND referenced_id=OBJECT_ID(N'toolbelt_json.TVF_ResolveJsonPointer',N'TF')) THROW 55592,N'Pointer: Abhängigkeit nach Ablehnung verloren.',10; DROP VIEW dbo.VW_PointerDependencyCI;"
    expect_central_confirm0_rejection "${central_db}"
    run_file confirm0_preserved_central "${central_db}" "${runtime}" Lifecycle.Tests.sql -v "ToolbeltDatabase=${central_db}"
    run_file uninstall_central "${central_db}" "${deployment}" Uninstall.sql -v ConfirmNoExternalConsumers=1
    run_file uninstall_local "${local_db}" "${deployment}" Uninstall.sql -v ConfirmNoExternalConsumers=0
    for database in "${local_db}" "${central_db}"; do
        run_query uninstall_disposition "${database}" "IF OBJECT_ID(N'toolbelt_json.TVF_ResolveJsonPointer') IS NOT NULL OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.pointer.Version') THROW 55592,N'Pointer: Uninstall ließ Releaseobjekte zurück.',8;"
    done
done

echo "PASS: JSON Pointer SQL ${sql_version} Linux; CL ${compatibility_levels}; local/central/consumer Contract, Safety, Client, Baseline, Repeat, central Dependency/Confirm0 und Uninstall."
