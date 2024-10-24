<h1 align="center"><strong>Pterodactyl Installer</strong></h1>
Instalador de Pterodactyl Con este script puedes instalar, actualizar o eliminar fácilmente el panel de Pterodactyl. Todo está reunido en un solo script. Por favor, ten en cuenta que este script está hecho para funcionar en una instalación nueva. Hay una buena posibilidad de que falle si no es una instalación nueva. El script debe ejecutarse como root. Lee sobre Pterodactyl aquí. Este script no está asociado con el proyecto oficial de Pterodactyl.

# Características
¡Compatible con la versión más reciente de Pterodactyl!
Este script es uno de los únicos que tiene una característica de cambio de dominios que funciona bien.

- Instalaciones
- Instalar Panel
- Instalar Wings
- Instalar Panel y Wings
- Instalar PHPMyAdmin
- Desinstalar PHPMyAdmin
- Cambiar Dominios de Pterodactyl
- Desinstalar Panel
- Desinstalar Wings
- Autoinstalación [SOLO NGINX & BETA]

# Sistemas Operativos y Servidores Web Soportados

Sistemas Operativos:

| Operating System | Version               | Supported                          |   PHP |
| ---------------- | ----------------------| ---------------------------------- | ----- |
| Ubuntu           | Desde  18.04 to 22.04 | :white_check_mark:                 | 8.1   |
| Debian           | Desde 11 to 12        | :white_check_mark:                 | 8.1   |
| CentOS           |       centos 7        | :white_check_mark:                 | 8.1   |
| Rocky Linux      | no supported versions | :x:                                | :x:   |


⚠️ Ten en cuenta que CentOS 7 está en fin de vida útil y no se añadirá soporte en este script para ninguna versión más nueva de CentOS. Si estás usando CentOS y quieres usar este script, deberías cambiarte a una nueva distribución, como Debian o Ubuntu.

Servidores Web:

NGINX ✅

Apache ✅

LiteSpeed ❌

Caddy ❌

Contribuyentes Copyright 2022-2023, Malthe K, me@malthe.cc Creado y mantenido por Malthe K.

Soporte El script ha sido probado muchas veces sin ningún arreglo de errores; sin embargo, aún pueden ocurrir. Si encuentras errores, siéntete libre de abrir un "Issue" en GitHub.

Instalación Interactiva/Normal La manera recomendada de usar este script.Instalador de Pterodactyl Con este script puedes instalar, actualizar o eliminar fácilmente el panel de Pterodactyl. Todo está reunido en un solo script. Por favor, ten en cuenta que este script está hecho para funcionar en una instalación nueva. Hay una buena posibilidad de que falle si no es una instalación nueva. El script debe ejecutarse como root. Lee sobre Pterodactyl aquí. Este script no está asociado con el proyecto oficial de Pterodactyl.

Características

¡Compatible con la versión más reciente de Pterodactyl!

Este script es uno de los únicos que tiene una característica de cambio de dominios que funciona bien.

Instalaciones

Instalar Panel

Instalar Wings

Instalar Panel y Wings

Instalar PHPMyAdmin

Desinstalar PHPMyAdmin

Cambiar Dominios de Pterodactyl

Desinstalar Panel

Desinstalar Wings

Autoinstalación [SOLO NGINX & BETA]

Sistemas Operativos y Servidores Web Soportados

Sistemas Operativos:

Ubuntu desde 18.04 hasta 22.04 ✅

Debian desde 11 hasta 12 ✅

CentOS 7 ✅

Rocky Linux (ninguna versión soportada) ❌❌

⚠️ Ten en cuenta que CentOS 7 está en fin de vida útil y no se añadirá soporte en este script para ninguna versión más nueva de CentOS. Si estás usando CentOS y quieres usar este script, deberías cambiarte a una nueva distribución, como Debian o Ubuntu.

Servidores Web:

NGINX ✅
Apache ✅
LiteSpeed ❌
Caddy ❌

Contribuyentes Copyright 2022-2023,
Soporte El script ha sido probado muchas veces sin ningún arreglo de errores; sin embargo, aún pueden ocurrir. Si encuentras errores, siéntete libre de abrir un "Issue" en GitHub.
Instalación Interactiva/Normal La manera recomendada de usar este script.

```bash <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/installer.sh)```
Raspbian
Only for raspbian users. They might need a extra < in the beginning.

bash < <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/installer.sh)
Autoinstall / Developer Installation
Only use this if you know what you are doing! You can now install Pterodactyl using 1 command without having to manually type anything after running the command.

[BETA] Generate Autoinstall Command
You can use my autoinstall command generator to install Pterodactyl and Wings with 1 command.

Required fields
<fqdn> = What you want to access your panel with. Eg. panel.domain.ltd
<ssl> = Whether to use SSL. Options are true or false.
<email> = Your email. If you choose SSL, it will be shared with Lets Encrypt.
<username> = Username for admin account on Pterodactyl
<firstname> = First name for admin account on Pterodactyl
<lastname> = Lastname for admin account on Pterodactyl
<password> = The password for the admin account on Pterodactyl
<wings> = Whether you want to have Wings installed automatically as well. Options are true or false.
You must be precise when using this script. 1 typo and everything can go wrong. It also needs to be run on a fresh version of Ubuntu or Debian.

bash <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/autoinstall.sh)  <fqdn> <ssl> <email> <username> <firstname <lastname> <password> <wings>
