using StackExchange.Redis;

namespace ADA.Core.Cache;

public interface IRedisCache
{
    public IDatabase GetDatabase();
}