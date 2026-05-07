local L = {}

-- Mapeamento de tipos para ox_lib (success, error, inform, warning)
L.notifysType = {
    ["sucesso"] = "success",
    ["erro"] = "error",
    ["importante"] = "inform"
}

L.textNotifys = {
    [1] = function(itens) return "Você não possui alguma ferramenta adequada para esta ação.  \n" .. itens end,
    [2] = function() return "Você não possui permissão para realizar essa ação" end,
    [3] = function() return "Esse veículo não pode ser modificado" end,
    [4] = function() return "Você saiu de perto do veículo, a instalação foi cancelada" end,
    [5] = function() return "Modulo instalado com sucesso" end,
    [6] = function() return "Você precisa estar dentro de um veículo" end,
    [7] = function() return "Falha ao instalar o Modulo, você não possui o item necessario" end,
    [8] = function() return "Modulo removido com sucesso do veículo" end,
}

return L