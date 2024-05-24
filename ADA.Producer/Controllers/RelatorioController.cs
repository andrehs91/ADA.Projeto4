using ADA.Producer.DTO;
using ADA.Producer.Services;
using Microsoft.AspNetCore.Mvc;
using System.Text.RegularExpressions;

namespace ADA.Producer.Controllers;

[ApiController]
[Route("api/relatorio")]
[Produces("application/json")]
public class RelatorioController(
    ILogger<RelatorioController> logger,
    IRelatorioService relatorioService) : ControllerBase
{
    private readonly ILogger<RelatorioController> _logger = logger;
    private readonly IRelatorioService _relatorioService = relatorioService;

    [HttpGet]
    [Route("gerar-relatorio")]
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(RespostaDTO), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<string>> GerarRelatorio(string contaOrigem)
    {
        if (!FormatoContaValido(contaOrigem))
        {
            return BadRequest(RespostaDTO.Aviso("Informe a conta no formato 0000.00000000."));
        }
        try
        {
            return Ok(await _relatorioService.GerarRelatorioAsync(contaOrigem));
        }
        catch (Exception e)
        {
            _logger.LogError(e, "RelatorioController.ConsultarRelatorio");
            return StatusCode(500, RespostaDTO.Erro("Entre em contato com o suporte."));
        }
    }

    [HttpGet]
    [Route("listar-relatorios")]
    [ProducesResponseType(typeof(List<string>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(RespostaDTO), StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<List<string>>> ListarRelatorios(string contaOrigem)
    {
        if (!FormatoContaValido(contaOrigem))
        {
            return BadRequest(RespostaDTO.Aviso("Informe a conta no formato 0000.00000000."));
        }
        try
        {
            var links = await _relatorioService.ListarRelatoriosAsync(contaOrigem);
            if (links is null) return Ok(RespostaDTO.Sucesso("Nenhum relatório foi encontrado para esta conta."));
            return Ok(links);
        }
        catch (Exception e)
        {
            _logger.LogError(e, "RelatorioController.ListarRelatorios");
            return StatusCode(500, RespostaDTO.Erro("Entre em contato com o suporte."));
        }
    }

    private static bool FormatoContaValido(string? conta)
    {
        if (string.IsNullOrEmpty(conta)) return false;
        if (!Regex.IsMatch(conta, @"^\d{4}\.\d{8}$")) return false;
        return true;
    }
}
