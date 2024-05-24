using ADA.Consumer.DTO;
using ADA.Consumer.Entities;
using ADA.Consumer.Services;
using ADA.Core.Settings;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace ADA.Consumer;

public class Worker(
    ILogger<Worker> logger,
    IAppSettings appSettings,
    IServiceScopeFactory serviceScopeFactory) : BackgroundService
{
    private readonly ILogger<Worker> _logger = logger;
    private readonly IAppSettings _appSettings = appSettings;
    private readonly IServiceScopeFactory _serviceScopeFactory = serviceScopeFactory;
    private IConnection? Connection;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            Connection ??= Connect();
            using var channel = Connection.CreateModel();
            channel.ExchangeDeclare(exchange: "ada.transacao", type: ExchangeType.Fanout);
            channel.QueueDeclare(queue: "fraude",
                                 durable: false,
                                 exclusive: false,
                                 autoDelete: false,
                                 arguments: null);
            channel.QueueBind(queue: "fraude",
                              exchange: "ada.transacao",
                              routingKey: "transacao");
            var consumer = new EventingBasicConsumer(channel);
            consumer.Received += async (model, ea) =>
            {
                byte[] body = ea.Body.ToArray();
                var message = Encoding.UTF8.GetString(body);
                var transacaoDTO = JsonSerializer.Deserialize<TransacaoDTO>(message);
                if (transacaoDTO is not null)
                {
                    using IServiceScope scope = _serviceScopeFactory.CreateScope();
                    try
                    {
                        _logger.LogInformation("Avaliando a transação da conta {ContaOrigem} efetuada em {DataHora}.", transacaoDTO.ContaOrigem, transacaoDTO.DataHora.ToString("dd/MM/yyyy HH':'mm':'ss"));
                        var consumerService = scope.ServiceProvider.GetRequiredService<IConsumerService>();
                        Transacao transacao = await consumerService.ProcessarTransacaoAsync(transacaoDTO.MapearParaEntidade());
                        _logger.LogInformation("Possui indício de fraude: {SimNao}.\n", transacao.Fraude ? "sim" : "não");
                    }
                    catch (Exception e)
                    {
                        _logger.LogError(e, message);
                    }
                }
            };
            channel.BasicConsume(queue: "fraude",
                                 autoAck: true,
                                 consumer: consumer);

            _logger.LogInformation("Consumer started at: {Time}", DateTimeOffset.Now);
            await Task.Delay(5000, stoppingToken);
        }
    }

    private IConnection Connect()
    {
        IConnection? connection = null;
        while (connection is null)
        {
            try
            {
                ConnectionFactory factory = new()
                {
                    HostName = _appSettings.GetValue("RabbitMQ:HostName"),
                    UserName = _appSettings.GetValue("RabbitMQ:UserName"),
                    Password = _appSettings.GetValue("RabbitMQ:Password")
                };
                connection = factory.CreateConnection();
            }
            catch (Exception e)
            {
                _logger.LogError(e, "Failed to connect to RabbitMQ {Message}:", e.Message);
                _logger.LogError("Retrying in 10 seconds...");
                Task.Delay(10000).Wait();
            }
        }
        return connection;
    }
}
