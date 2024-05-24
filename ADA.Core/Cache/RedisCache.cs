using ADA.Core.Settings;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace ADA.Core.Cache;

public class RedisCache(
    ILogger<RedisCache> logger,
    IAppSettings appSettings) : IRedisCache
{
    private readonly ILogger<RedisCache> _logger = logger;
    private readonly string _hostname = appSettings.GetValue("Redis:Hostname");
    private readonly string _password = appSettings.GetValue("Redis:Password");
    private IDatabase? _database;

    public IDatabase GetDatabase()
    {
        _database ??= Connect(_hostname, _password);
        return _database;
    }

    private IDatabase Connect(string hostname, string password)
    {
        var configuration = ConfigurationOptions.Parse($"{hostname}:6379");
        configuration.Password = password;

        int tries = 0;
        IDatabase? database = null;
        while (database is null)
        {
            try
            {
                var redis = ConnectionMultiplexer.Connect(configuration);
                database = redis.GetDatabase();
            }
            catch (Exception e)
            {
                tries++;
                _logger.LogWarning("Failed to connect to Redis: {Message}", e.Message);
                _logger.LogWarning("Retrying in 20 seconds...");
                if (tries < 10) Task.Delay(20000).Wait();
                else throw;
            }
        }
        _logger.LogInformation("Connected to Redis.");
        return database;
    }
}
