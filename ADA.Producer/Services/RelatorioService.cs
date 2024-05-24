using ADA.Core.Cache;
using ADA.Core.Settings;
using Azure;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Specialized;
using Azure.Storage.Sas;

namespace ADA.Producer.Services;

public class RelatorioService(
    ILogger<RelatorioService> logger,
    IAppSettings appSettings,
    IRedisCache redisCache) : IRelatorioService
{
    private readonly ILogger<RelatorioService> _logger = logger;
    private readonly IAppSettings _appSettings = appSettings;
    private readonly IRedisCache _redisCache = redisCache;

    public async Task<string> GerarRelatorioAsync(string contaOrigem)
    {
        var db = _redisCache.GetDatabase();
        string chaveTransacaoInvalida = "invalida." + contaOrigem;
        var transacoesInvalidas = await db.ListRangeAsync(chaveTransacaoInvalida);

        if (transacoesInvalidas.Length == 0)
            return "Conta não possui registro de transações fraudulentas ou todos os registros já foram enviados para o relatório.";

        string content = "[";
        foreach (var transacao in transacoesInvalidas) content += transacao + ",";
        content = content.Remove(content.Length - 1, 1) + "]";
        var memoryStream = new MemoryStream();
        var streamWriter = new StreamWriter(memoryStream);
        streamWriter.Write(content);
        streamWriter.Flush();
        memoryStream.Position = 0;

        BlobContainerClient blobContainerClient = await BlobContainerAsync("ada");
        string blobName = $"{contaOrigem}_{DateTime.Now:yyyyMMddHHmmss}.txt";
        BlobClient blobClient = blobContainerClient.GetBlobClient(blobName);
        await blobClient.UploadAsync(memoryStream, true);

        streamWriter.Dispose();
        memoryStream.Dispose();

        await db.KeyDeleteAsync(chaveTransacaoInvalida);

        if (blobClient.CanGenerateSasUri)
        {
            BlobSasBuilder sasBuilder = new()
            {
                BlobContainerName = blobClient.GetParentBlobContainerClient().Name,
                BlobName = blobClient.Name,
                Resource = "b",
                ExpiresOn = DateTimeOffset.UtcNow.AddDays(1)
            };
            sasBuilder.SetPermissions(BlobContainerSasPermissions.Read);
            Uri sasURI = blobClient.GenerateSasUri(sasBuilder);
            string link = sasURI.AbsoluteUri;
            db.SetAdd("relatorios." + contaOrigem, link);
            return link;
        }
        else
        {
            return "O relatório foi gerado, mas não foi possível gerar um link para download.";
        }
    }

    public async Task<List<string>?> ListarRelatoriosAsync(string contaOrigem)
    {
        var db = _redisCache.GetDatabase();
        var cache = await db.SetMembersAsync("relatorios." + contaOrigem);
        if (cache.Length == 0) return null;
        List<string> links = cache.Select(c => c.ToString()).ToList();
        return links;
    }

    private async Task<BlobContainerClient> BlobContainerAsync(string containerName)
    {
        string connectionString = _appSettings.GetValue("ConnectionStrings:AzureStorageAccount");
        BlobContainerClient blobContainerClient = new(connectionString, containerName);
        if (!await blobContainerClient.ExistsAsync())
        {
            try
            {
                BlobServiceClient blobServiceClient = new(connectionString);
                blobContainerClient = await blobServiceClient.CreateBlobContainerAsync(containerName);
            }
            catch (RequestFailedException e)
            {
                _logger.LogError(e, "Erro na criação do container.");
            }
        }
        return blobContainerClient;
    }
}
