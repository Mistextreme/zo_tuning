menuTuning = {
    comando = "zotuning", 
    permissoesAcessarMenu = { "Admin" },
    itensObrigatorioAcessar = { "notebook" }, -- { "notebook" },

    itensObrigatorioInstalarModulo = {  }, -- { "chavefenda" },
    permissoesInstalarModulo = {  }, -- { "mecanico.permissao" },
    
    itensObrigatorioRemoverModulo = {  }, -- { "chavefenda" },
    permissoesRemoverModulo = {  }, -- { "mecanico.permissao" },
}

configuracaoModulos = {
    ["suspensao"] = { 
        nome = "Suspensão a Ar",
        img = "https://imgur.com/61xZT0o.png",
        desabilitar = true,
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "suspensaoar",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["neon"] = { 
        nome = "Neon",
        img = "https://imgur.com/UU8pPxM.png",
        desabilitar = false,
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitneon",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = { }
    },
    ["xenon"] = { 
        nome = "Xenon",
        img = "https://imgur.com/XAUopVB.png",
        desabilitar = false,
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitxenon",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["camber"] = { 
        nome = "Camber",
        img = "https://imgur.com/qHamoRI.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitcamber",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["offset"] = { 
        nome = "OffSet",
        img = "https://imgur.com/qHamoRI.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitoffset",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["antiLag"] = { 
        nome = "Pops' Bangs",
        img = "https://imgur.com/NzhQ3t7.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "escapamentoPop",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["remap"] = { 
        nome = "Fueltech",
        img = "https://imgur.com/0rfEpay.png",
        desabilitar = false,
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "fueltech",
            tempoAnimacaoInstalacao = 5
        },
        permsAcessarMenu = {  }
    },
    ["westgate"] = { 
        nome = "Westgate",
        img = "https://imgur.com/LTBaZGg.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "westgate",
            tempoAnimacaoInstalacao = 0
        },
        permsAcessarMenu = {  }
    },
    ["purgador"] = { 
        nome = "Purgador",
        img = "https://imgur.com/yV76b2d.png",
        desabilitar = true,
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "purgador",
            tempoAnimacaoInstalacao = 0
        },
        permsAcessarMenu = {  }
    },
}

remapOptions = {
    { field = "fInitialDriveForce", key = "torque", title = "Torque", step = 0.01, var = 0.1 },
    { field = "fDriveInertia", key = "rotation", title = "Aceleração Motor", step = 0.01, var = 0.1 },
    { field = "fSteeringLock", key = "steering", title = "Ângulo", step = 1, var = 35 },
    { field = "fBrakeForce", key = "brakeForce", title = "Força de frenagem", step = 0.01, var = 0.2 },
    { field = "fTractionCurveMax", key = "curvedgrip", title = "Aderência nas curvas", step = 0.01, var = 1.5 },
}

veiculosBlackList = {
    ["kuruma"] = true,
    ["t20"] = true,
}