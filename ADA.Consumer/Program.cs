using ADA.Consumer;
using ADA.Consumer.Services;
using ADA.Core.Cache;
using ADA.Core.Settings;

var builder = Host.CreateApplicationBuilder(args);
builder.Services.AddHostedService<Worker>();
builder.Services.AddSingleton<IAppSettings, AppSettings>();
builder.Services.AddSingleton<IRedisCache, RedisCache>();
builder.Services.AddScoped<IConsumerService, ConsumerService>();

var host = builder.Build();
host.Run();
