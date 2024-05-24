using ADA.Core.Settings;
using Microsoft.AspNetCore.Mvc;
using RabbitMQ.Client;
using StackExchange.Redis;

namespace ADA.Producer.Controllers;

[ApiController]
[Route("api/transacao")]
[Produces("application/json")]
public class Depuracao(IAppSettings appSettings) : ControllerBase
{
    private readonly IAppSettings _appSettings = appSettings;

    [HttpGet]
    [Route("consultar-variaveis-rabbitmq")]
    public IActionResult ConsultarVariaveisRabbitmq()
    {
        try
        {
            var resposta = new
            {
                HostName = _appSettings.GetValue("RabbitMQ:HostName"),
                UserName = _appSettings.GetValue("RabbitMQ:UserName"),
                Password = _appSettings.GetValue("RabbitMQ:Password"),
            };
            return Ok(resposta);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    [HttpGet]
    [Route("testar-conexao-rabbitmq")]
    public IActionResult TestarConexaoRabbitMQ()
    {
        try
        {
            ConnectionFactory factory = new()
            {
                HostName = _appSettings.GetValue("RabbitMQ:HostName"),
                UserName = _appSettings.GetValue("RabbitMQ:UserName"),
                Password = _appSettings.GetValue("RabbitMQ:Password")
            };
            factory.CreateConnection();
            return Ok("Connected to RabbitMQ.");
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    [HttpGet]
    [Route("consultar-variaveis-redis")]
    public IActionResult ConsultarVariaveisRedis()
    {
        try
        {
            var resposta = new
            {
                HostName = _appSettings.GetValue("Redis:HostName"),
                Password = _appSettings.GetValue("Redis:Password"),
            };
            return Ok(resposta);
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }

    [HttpGet]
    [Route("testar-conexao-redis")]
    public IActionResult TestarConexaoRedis()
    {
        string hostname = _appSettings.GetValue("Redis:Hostname");
        string password = _appSettings.GetValue("Redis:Password");
        var configuration = ConfigurationOptions.Parse($"{hostname}:6379");
        configuration.Password = password;

        try
        {
            var redis = ConnectionMultiplexer.Connect(configuration);
            redis.GetDatabase();
            return Ok("Connected to Redis.");
        }
        catch (Exception e)
        {
            return Problem(e.Message);
        }
    }
}
