$(document).ready(function () {
    // Función para actualizar el HUD del jugador (Vida, Escudo, Hambre, Sed, etc.)
    function updatePlayerHUD(data) {
        const perimeter = 120; // Longitud del arco de los pentágonos

        // Actualizar Vida
        let healthOffset = perimeter - (perimeter * (data.health / 100));
        $('#health-progress').css('stroke-dashoffset', healthOffset);
        if (data.health <= 0) { $('#health-progress').css('opacity', '0'); } else { $('#health-progress').css('opacity', '1'); }

        // Actualizar Escudo
        let armorOffset = perimeter - (perimeter * (data.armor / 100));
        $('#armor-progress').css('stroke-dashoffset', armorOffset);
        if (data.armor <= 0) { $('#armor-progress').css('opacity', '0'); } else { $('#armor-progress').css('opacity', '1'); }

        // Actualizar Sed
        let thirstOffset = perimeter - (perimeter * (data.thirst / 100));
        $('#thirst-progress').css('stroke-dashoffset', thirstOffset);
        if (data.thirst <= 0) { $('#thirst-progress').css('opacity', '0'); } else { $('#thirst-progress').css('opacity', '1'); }
        if (data.thirst < 25) { $('#thirst-container').addClass('low-status'); } else { $('#thirst-container').removeClass('low-status'); }

        // Actualizar Hambre
        let hungerOffset = perimeter - (perimeter * (data.hunger / 100));
        $('#hunger-progress').css('stroke-dashoffset', hungerOffset);
        if (data.hunger <= 0) { $('#hunger-progress').css('opacity', '0'); } else { $('#hunger-progress').css('opacity', '1'); }
        if (data.hunger < 25) { $('#hunger-container').addClass('low-status'); } else { $('#hunger-container').removeClass('low-status'); }

        // Actualizar Resistencia (Stamina)
        let staminaOffset = perimeter - (perimeter * (data.stamina / 100));
        $('#stamina-progress').css('stroke-dashoffset', staminaOffset);
        if (data.stamina <= 0) { $('#stamina-progress').css('opacity', '0'); } else { $('#stamina-progress').css('opacity', '1'); }

        // Actualizar Voz (Nivel de proximidad)
        let voiceLevel = 33;
        if (data.voice <= 1.5) {
            voiceLevel = 33;
        } else if (data.voice <= 3.0) {
            voiceLevel = 66;
        } else {
            voiceLevel = 100;
        }
        let voiceOffset = perimeter - (perimeter * (voiceLevel / 100));
        $('#voice-progress').css('stroke-dashoffset', voiceOffset);

        // Cambiar color si está hablando
        if (data.talking) {
            $('#voice-container').addClass('talking');
        } else {
            $('#voice-container').removeClass('talking');
        }

        // Actualizar Oxígeno (Bajo el agua)
        let oxygenOffset = perimeter - (perimeter * (data.oxygen / 100));
        $('#oxygen-progress').css('stroke-dashoffset', oxygenOffset);
        if (data.oxygen <= 0) { $('#oxygen-progress').css('opacity', '0'); } else { $('#oxygen-progress').css('opacity', '1'); }
        if (data.oxygen < 100) {
            $('#oxygen-container').fadeIn('slow');
        } else {
            $('#oxygen-container').fadeOut('slow');
        }
        if (data.oxygen < 25) { $('#oxygen-container').addClass('low-status'); } else { $('#oxygen-container').removeClass('low-status'); }

        // Alerta de vida baja
        if (data.health < 25) { $('#health-container').addClass('low-status'); } else { $('#health-container').removeClass('low-status'); }

        // Asegurar que los contenedores básicos siempre se vean
        $('#health-container, #armor-container, #thirst-container, #hunger-container, #stamina-container, #voice-container').show();
    }

    // Función para actualizar el HUD del Vehículo (Velocidad, RPM, Gasolina, etc.)
    function updateVehicleHUD(data) {
        // Cálculo de las RPM (arco de 270 grados)
        const speedPerimeter = 283;
        let rpmDash = data.rpm * 212;
        $('#speed-progress').css('stroke-dasharray', `${rpmDash} ${speedPerimeter}`);

        // Efectos de vibración y Redline según las RPM
        if (data.rpm > 0.85) {
            $('#speed-container').addClass('redline').removeClass('vibrate');
        } else if (data.rpm > 0.1 && data.rpm < 0.4) {
            $('#speed-container').addClass('vibrate').removeClass('redline');
        } else {
            $('#speed-container').removeClass('redline').removeClass('vibrate');
        }

        // Vibración del HUD a altas velocidades (> 150 km/h)
        if (data.speed > 150) {
            $('#vehicle-hud-container').addClass('hud-vibrate');
        } else {
            $('#vehicle-hud-container').removeClass('hud-vibrate');
        }

        // Mostrar velocidad con ceros a la izquierda
        $('#speed').text(data.speed.toString().padStart(2, '0'));

        // Actualizar barra de Gasolina
        const fuelPath = 126;
        let fuelOffset = fuelPath - (fuelPath * (data.fuel / 100));
        $('#fuel-progress').css('stroke-dashoffset', fuelOffset);

        // Cambiar color de la barra de gasolina si está baja
        if (data.fuel < 20) {
            $('#fuel-progress').css('stroke', '#ff4d6d');
        } else {
            $('#fuel-progress').css('stroke', '#ffffff');
        }

        // Marcha actual (R para marcha atrás)
        $('#gear').text(data.gear == 0 ? 'R' : data.gear);

        // Estado del Cinturón e Icono
        if (data.seatbelt) {
            $('#seatbelt-icon').addClass('active').removeClass('warning').find('i').attr('class', 'fas fa-user-check');
        } else {
            $('#seatbelt-icon').removeClass('active').addClass('warning').find('i').attr('class', 'fas fa-user-slash');
        }

        // Estado de las puertas (Cerrado/Abierto)
        if (data.locked) {
            $('#lock-icon').addClass('active').find('i').attr('class', 'fas fa-lock');
        } else {
            $('#lock-icon').removeClass('active').find('i').attr('class', 'fas fa-lock-open');
        }

        // Mostrar/Ocultar HUD si el motor está apagado
        if (data.engine) {
            $('#speed-container, #fuel-container, #gear-container, #vehicle-status-icons').css('opacity', '1');
            $('#speed-progress').css('opacity', '1');
        } else {
            $('#speed-container, #fuel-container, #gear-container, #vehicle-status-icons').css('opacity', '0');
            $('#speed-progress').css('opacity', '0');
        }
    }

    // Escuchar mensajes enviados desde el cliente (Lua)
    window.addEventListener('message', function (event) {
        const data = event.data;
        if (data.action == 'showPlayerHUD') {
            $('body').fadeIn('slow')
        } else if (data.action == 'hidePlayerHUD') {
            $('body').fadeOut('slow')
        } else if (data.action == 'updatePlayerHUD') {
            updatePlayerHUD(data)
        } else if (data.action == 'showVehicleHUD') {
            $('#vehicle-hud-container').fadeIn('slow');
            $('#compass-container').fadeIn('slow');
        } else if (data.action == 'hideVehicleHUD') {
            $('#vehicle-hud-container').fadeOut('slow');
            $('#compass-container').fadeOut('slow');
        } else if (data.action == 'updateVehicleHUD') {
            updateVehicleHUD(data)
        } else if (data.action == 'updateLocationHUD') {
            updateLocationHUD(data)
        }
    })

    // Función para la brújula y los nombres de las calles
    function updateLocationHUD(data) {
        if (data.heading !== undefined) {
            // Cálculo del desplazamiento de la brújula basado en el heading
            // Heading 0-360. Each 45 deg = 100px. 1 deg = 2.222px.
            // Offset 125px to center the first 'N'.
            let heading = 360 - data.heading; // Compass scrolls opposite to heading
            let move = 125 + (heading * 2.222);
            $('.compass-bar').css('transform', `translateX(${-move}px)`);
        }

        // Actualizar nombres de calles (con fallback por si falla)
        if (data.street1) {
            $('#street1').text(data.street1);
        } else {
            $('#street1').text('Zona desconocida');
        }

        if (data.street2) {
            $('#street2').text(data.street2);
            $('#street2').show();
        } else {
            $('#street2').hide();
        }
    }
});