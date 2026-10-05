-- Qualifizierte Offline-Corezeile; keine Trustfreigabe und keine Runtimeableitung.
DECLARE @JsonCoreKnownHash varbinary(64)=0x4680e9d34a0870924b5ca003cc5983882fc8ffb653e702bcc549e5f65dde11934c55ba7b356b519503ac5ce1e2478fe64876fea0295176ff13b5b4a6ab61b894,
 @JsonCoreArtifactId varchar(64)='975d4a84bb86e80b6e5844d6e86785ae0e98b13ee44c0f66c021507a23e0f888',
 @JsonCoreId int,@JsonCoreOwner int,@JsonCoreHash varbinary(64),
 @JsonCoreVersion nvarchar(max),@JsonCoreStoredMode nvarchar(max),
 @JsonCoreExpectedMode nvarchar(max),@JsonCoreRequired bit=1,@JsonCoreRemoving bit=0;
DECLARE @JsonCoreMarkers TABLE(Name sysname PRIMARY KEY,Value sql_variant NOT NULL);
