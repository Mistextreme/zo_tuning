Config = {}

Config.MenuTuning = {
    comando = "zt", 
    jobsAcessarMenu = { 'admin', 'mechanic' }, -- Grupos/Jobs do ESX
    itensObrigatorioAcessar = { }, -- Ex: { "notebook" }

    itensObrigatorioInstalarModulo = { }, 
    jobsInstalarModulo = { 'admin', 'mechanic' },
    
    itensObrigatorioRemoverModulo = { }, 
    jobsRemoverModulo = { 'admin', 'mechanic' },
}

Config.NetworkPopsAndBangs = {
    som = true,
    particulas = true
}

Config.ConfiguracaoModulos = {
    ["suspensao"] = { 
        nome = "Suspensão a Ar",
        img = "https://i.postimg.cc/G2P1T2D1/61xZT0o.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "suspensaoar",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = { }
    },
    ["neon"] = { 
        nome = "Neon",
        img = "https://i.postimg.cc/L87SrGSG/UU8pPxM.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitneon",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = { }
    },
    ["xenon"] = { 
        nome = "Xenon",
        img = "https://i.postimg.cc/N0HtYbfF/XAUopVB.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitxenon",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = {  }
    },
    ["camber"] = { 
        nome = "Camber",
        img = "https://i.postimg.cc/DZ3Tzs8g/qHamoRI.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitcamber",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = {  }
    },
    ["offset"] = { 
        nome = "OffSet",
        img = "https://i.postimg.cc/DZ3Tzs8g/qHamoRI.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "kitoffset",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = {  }
    },
    ["antiLag"] = { 
        nome = "Pops' Bangs",
        img = "https://i.postimg.cc/QdVsYh2p/NzhQ3t7.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "escapamentoPop",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = {  }
    },
    ["remap"] = { 
        nome = "Fueltech",
        img = "https://i.postimg.cc/NfsQT1bC/0rfEpay.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "fueltech",
            tempoAnimacaoInstalacao = 5
        },
        jobsAcessarMenu = {  }
    },
    ["westgate"] = { 
        nome = "Westgate",
        img = "https://i.postimg.cc/tJXG3jdn/LTBaZGg.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "westgate",
            tempoAnimacaoInstalacao = 1 -- Ajustado para evitar erro 0
        },
        jobsAcessarMenu = {  }
    },
    ["purgador"] = { 
        nome = "Purgador",
        img = "https://i.postimg.cc/L6x2Vnb9/yV76b2d.png",
        configItem = {
            obrigatorioItemInstaladoParaAcessar = false,
            nameItem = "purgador",
            tempoAnimacaoInstalacao = 1
        },
        jobsAcessarMenu = {  }
    },
}

Config.RemapOptions = {
    { field = "fInitialDriveForce", key = "torque", title = "Torque", step = 0.01, var = 0.1 },
    { field = "fDriveInertia", key = "rotation", title = "Aceleração Motor", step = 0.01, var = 0.1 },
    { field = "fSteeringLock", key = "steering", title = "Ângulo", step = 1, var = 35 },
    { field = "fBrakeForce", key = "brakeForce", title = "Força de frenagem", step = 0.01, var = 0.2 },
    { field = "fTractionCurveMax", key = "curvedgrip", title = "Aderência nas curvas", step = 0.01, var = 1.5 },
}

Config.VeiculosBlackList = {
    ["kuruma"] = true,
    ["t20"] = true,
}