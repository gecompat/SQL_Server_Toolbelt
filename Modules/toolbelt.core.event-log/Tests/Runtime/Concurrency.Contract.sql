SET NOCOUNT ON;
DECLARE @Worker int=$(WorkerId);
DECLARE @Caller int=@@SPID;
DECLARE @Data nvarchar(max)=N'{"worker":'+CONVERT(nvarchar(12),@Worker)+N',"caller":'+CONVERT(nvarchar(12),@Caller)+N'}';
EXEC toolbelt_core.USP_WriteEvent @EventName='test.concurrent',@Category='worker',@DataJson=@Data;
