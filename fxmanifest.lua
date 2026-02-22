-- Versión de FiveM necesaria para el recurso
fx_version 'cerulean'
-- Autor del script
author 'mfl'
-- Descripción del recurso
description 'HUD de jugador y vehículo simple y premium para FiveM'
-- Juego compatible
game 'gta5'
-- Usar la última versión de Lua
lua54 'yes'

-- Scripts compartidos (se cargan tanto en cliente como en servidor)
shared_scripts {
    '@ox_lib/init.lua', -- Librería base de Ox
    'config.lua',       -- Configuración general del HUD
}

-- Scripts que solo se ejecutan en el lado del cliente
client_scripts {
    'client/*.lua', -- Todos los archivos en la carpeta client
}

-- Scripts que solo se ejecutan en el lado del servidor
server_scripts {
    'server/*.lua', -- Todos los archivos en la carpeta server
}

-- Página principal de la interfaz (NUI)
ui_page 'web/index.html'

-- Archivos necesarios para que la interfaz funcione (HTML, CSS, JS, etc.)
files {
    'web/*.html',
    'web/*.css',
    'web/*.js'
}
