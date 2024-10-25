<h1 align="center"><strong>Instalador de Pterodactyl</strong></h1> 
Con este script puedes instalar, actualizar o eliminar fácilmente el Panel Pterodactyl. Todo está reunido en un solo script. 

Tenga en cuenta que este script está hecho para funcionar en una instalación nueva. Existe una buena probabilidad de que falle si no es una instalación nueva. El script debe ejecutarse como root. 
Lee sobre [Pterodactyl](https://pterodactyl.io) aquí. Este script no está asociado con el Proyecto Pterodactyl oficial.

# Características

¡Soporta la versión más reciente de Pterodactyl! Este script es uno de los únicos que tiene una función de Cambio de Dominios que funciona bien.

- Instalar Panel
- Instalar Wings
- Instalar Panel y Wings
- Instalar PHPMyAdmin
- Desinstalar PHPMyAdmin
- Cambiar Dominios de Pterodactyl
- Desinstalar Panel
- Desinstalar Wings
- Autoinstalación [SOLO NGINX y BETA]

# Sistemas Operativos y Servidores Web Soportados

| Sistema Operativo| Versión               | Soportado                          |   PHP |
| ---------------- | ----------------------| ---------------------------------- | ----- |
| Ubuntu           | DE 18.04 to 22.04     | :white_check_mark:                 | 8.1   |
| Debian           | DE 11 to 12           | :white_check_mark:                 | 8.1   |
| CentOS           |       centos 7        | :white_check_mark:                 | 8.1   |
| Rocky Linux      | No Hay Versiones      | :x:                                | :x:   |

:warning: Tenga cuidado al usar CentOS 7. Está en EOL y no se añadirá soporte en este script para ninguna versión más reciente de CentOS. Si está usando CentOS y quiere usar este script, debería cambiar a una nueva distro, como Debian o Ubuntu.

| Servidor Web     | Soportado           |
| ---------------- | --------------------| 
| NGINX            | :white_check_mark:  |
| Apache           | :white_check_mark:  |
| LiteSpeed        | :x:                 |
| Caddy            | :x:                 |

# Contrubuyentes

Copyright 2024-2025, [ItzRaikk](https://github.com/itzraikk), contacto@itzraaikk.dev
<br>
Traducido y Mantenido Por [ItzRaikk](https://github.com/itzraikk)
Creado Por [Malte K.](https://github.com/guldkage)

# Soporte

El script ha sido probado muchas veces sin ningún error, sin embargo, aún pueden ocurrir. Si encuentras errores, siéntete libre de abrir un "Soporte" en Discord

# Instalación Interactiva/Normal
La forma recomendada de usar este script.

```bash
bash <(curl -s https://raw.githubusercontent.com/itzraikk/Pterodactyl-Installer/main/installer.sh)
```

# Raspbian
Solo para usuarios de Raspbian. Podrían necesitar un extra < al inicio.
```bash
bash < <(curl -s https://raw.githubusercontent.com/guldkage/Pterodactyl-Installer/main/installer.sh)
```

# Autoinstalación / Instalación para Desarrolladores
¡Solo usa esto si sabes lo que estás haciendo! Ahora puedes instalar Pterodactyl usando un comando sin tener que escribir nada manualmente después de ejecutar el comando.

### Campos Requeridos
```
<fqdn> = Lo que quieres usar para acceder a tu panel. Ej. panel.dominio.ltd
<ssl> = Si deseas usar SSL. Las opciones son true o false.
<email> = Tu email. Si eliges SSL, se compartirá con Lets Encrypt.
<username> = Nombre de usuario para la cuenta de administrador en Pterodactyl
<firstname> = Primer nombre para la cuenta de administrador en Pterodactyl
<lastname> = Apellido para la cuenta de administrador en Pterodactyl
<password> = La contraseña para la cuenta de administrador en Pterodactyl
<wings> = Si deseas tener Wings instalado automáticamente también. Las opciones son true o false.
```

Debes ser preciso al usar este script. Un error tipográfico y todo puede salir mal. También necesita ejecutarse en una versión nueva de Ubuntu o Debian.

```bash
bash <(curl -s https://raw.githubusercontent.com/itzraikk/Pterodactyl-Installer/main/autoinstall.sh)  <fqdn> <ssl> <email> <username> <firstname <lastname> <password> <wings>
```
