# Configuración de Email con Resend

Esta guía te ayudará a configurar el envío de cotizaciones por correo electrónico usando **Resend**, un servicio de envío de emails transaccionales profesional.

## 🚀 Resumen Rápido

1. ✅ Crea una cuenta gratuita en Resend
2. ✅ Genera una API key
3. ✅ Configura la API key en tu aplicación
4. ✅ (Recomendado) Verifica tu dominio personalizado
5. ✅ Configura el email de envío en Ajustes

---

## Error: "API key is invalid"

Si ves este error, significa que necesitas configurar correctamente tu API key de Resend.

## Pasos para configurar Resend

### 1. Crear cuenta en Resend
1. Ve a [https://resend.com](https://resend.com)
2. Haz clic en "Sign Up" para crear una cuenta gratuita
3. Verifica tu email

### 2. Obtener API Key
1. Una vez dentro de tu cuenta, ve a [https://resend.com/api-keys](https://resend.com/api-keys)
2. Haz clic en "Create API Key"
3. Dale un nombre descriptivo (ej: "IDEALLY Cotizaciones")
4. Selecciona los permisos necesarios (por defecto "Full Access" está bien)
5. Haz clic en "Add"
6. **IMPORTANTE**: Copia la API key que aparece (empieza con `re_...`)
   - Solo se mostrará una vez, guárdala en un lugar seguro

### 3. Configurar la API Key en tu aplicación
1. En Figma Make, busca el modal que te pide la API key de Resend
2. Pega la API key que copiaste (debe empezar con `re_`)
3. Guarda la configuración

### 4. Verificar tu dominio personalizado (IMPORTANTE)

Con el plan gratuito de Resend, puedes usar `onboarding@resend.dev` como remitente temporal, **pero es altamente recomendable verificar tu propio dominio** para:
- Enviar desde tu email profesional (ej: ventas@ideally.com.mx)
- Mejorar la entregabilidad de los emails
- Evitar que lleguen a spam
- Darle más profesionalismo a tus cotizaciones

#### Pasos para verificar tu dominio:

1. **Accede a Resend Domains**
   - Ve a [https://resend.com/domains](https://resend.com/domains)
   - Haz clic en "Add Domain"

2. **Ingresa tu dominio**
   - Escribe solo el dominio base (ej: `ideally.com.mx`)
   - No incluyas subdominios ni protocolos (no escribas `www` o `https://`)

3. **Configura los registros DNS**
   Resend te mostrará 3 registros DNS que debes agregar:
   
   - **Registro SPF (TXT)**: Permite que Resend envíe emails desde tu dominio
   - **Registro DKIM (TXT)**: Firma digitalmente tus emails para evitar spam
   - **Registro DMARC (TXT)**: Configura políticas de autenticación
   
   Ejemplo de registros:
   ```
   Tipo: TXT
   Nombre: @
   Valor: v=spf1 include:resend.com ~all
   
   Tipo: TXT
   Nombre: resend._domainkey
   Valor: [valor proporcionado por Resend]
   
   Tipo: TXT
   Nombre: _dmarc
   Valor: v=DMARC1; p=none
   ```

4. **Agregar registros en tu proveedor de dominio**
   
   Dependiendo de dónde tengas tu dominio (GoDaddy, Namecheap, Google Domains, etc.):
   - Accede al panel de control de tu dominio
   - Busca la sección de "DNS" o "Administrar DNS"
   - Agrega cada registro DNS tal como te lo indica Resend
   - **IMPORTANTE**: Copia exactamente los valores, sin espacios adicionales
   
   ⏱️ **Los cambios DNS pueden tardar entre 15 minutos y 48 horas en propagarse**

5. **Verificar el dominio en Resend**
   - Regresa a Resend y haz clic en "Verify"
   - Si los registros DNS están correctos, verás un ✅ de verificación
   - Si no se verifica de inmediato, espera unas horas e intenta de nuevo

6. **Configurar email de envío en tu aplicación**
   - Ve a **Ajustes > Configuración de Emails**
   - En el campo "Email de envío", escribe tu email verificado (ej: `ventas@ideally.com.mx`)
   - Guarda los cambios

#### Consejos importantes:

- ✅ **Email correcto**: `ventas@ideally.com.mx`
- ❌ **Email incorrecto**: `ventas@resend.dev` (no funciona, Resend no permite esto)
- ✅ **Puedes usar cualquier dirección de tu dominio verificado**: `contacto@`, `cotizaciones@`, etc.
- 💡 **No necesitas que el email exista**: Resend enviará desde ese email aunque no tengas una casilla configurada

#### ¿Tienes problemas con DNS?

Si no sabes cómo agregar registros DNS, busca la documentación específica de tu proveedor:
- **GoDaddy**: [Cómo agregar registros DNS](https://mx.godaddy.com/help/add-a-txt-record-19232)
- **Namecheap**: [Cómo agregar registros TXT](https://www.namecheap.com/support/knowledgebase/article.aspx/317/2237/)
- **Google Domains**: [Agregar registros de recursos](https://support.google.com/domains/answer/3290350)

**Nota**: Con el plan gratuito de Resend, puedes verificar 1 dominio.

## Límites del plan gratuito de Resend

- **100 emails/día** - Suficiente para enviar cotizaciones
- **3,000 emails/mes**
- 1 dominio verificado
- Soporte por email

## Solución de problemas

### Error: "API key is invalid"
- Verifica que copiaste la API key completa (debe empezar con `re_`)
- Asegúrate de que no haya espacios al inicio o final
- Genera una nueva API key si es necesario

### Error: "from email not verified" o "Domain not verified"
- Este error significa que el dominio que estás usando en el "Email de envío" no está verificado en Resend
- **Solución inmediata**: Cambia el email de envío a `onboarding@resend.dev` temporalmente
- **Solución definitiva**: Sigue los pasos de la sección "Verificar tu dominio personalizado" arriba
- Verifica que hayas agregado correctamente los 3 registros DNS (SPF, DKIM, DMARC)
- Espera hasta 48 horas para que los cambios DNS se propaguen
- Una vez verificado el dominio en Resend, actualiza el email de envío en Ajustes

### Los emails no llegan
- Revisa la carpeta de spam del destinatario
- Verifica que el email del destinatario sea correcto
- Revisa el log de actividad en el dashboard de Resend

## 📧 Cómo usar tu dominio verificado en la aplicación

Una vez que hayas verificado tu dominio en Resend:

1. Abre tu aplicación de cotizaciones
2. Ve a **Ajustes** (menú lateral izquierdo)
3. Desplázate hasta la sección **"Configuración de Emails"**
4. En el campo **"Email de Envío"**, ingresa tu email verificado
   - Ejemplo: `ventas@ideally.com.mx`
   - Puedes usar cualquier dirección de tu dominio verificado
   - No necesitas crear la casilla de correo, Resend enviará desde ese remitente
5. Haz clic en **"Guardar Ajustes"**

**¡Listo!** Ahora cuando envíes cotizaciones por email, se enviarán desde tu dominio profesional.

## 💡 Preguntas Frecuentes

### ¿Puedo enviar emails sin verificar mi dominio?

Sí, pero los emails se enviarán desde `onboarding@resend.dev`. Esto funciona para pruebas, pero no es recomendable para producción porque:
- No luce profesional
- Mayor probabilidad de caer en spam
- No puedes personalizar el remitente

### ¿Cuánto cuesta Resend?

Resend tiene un plan gratuito muy generoso:
- **100 emails/día** - Suficiente para enviar cotizaciones
- **3,000 emails/mes**
- 1 dominio verificado

### ¿Necesito tener un servidor de correo?

No. Resend maneja todo el envío de correos por ti. Solo necesitas:
1. Tener un dominio (ej: ideally.com.mx)
2. Acceso para agregar registros DNS
3. Verificar el dominio en Resend

### ¿Qué pasa si mi dominio no se verifica?

Si después de 48 horas tu dominio no se verifica:
1. Revisa que hayas copiado correctamente los registros DNS
2. Verifica que no haya espacios adicionales en los valores
3. Consulta con tu proveedor de dominio si tienen restricciones especiales
4. Contacta al soporte de Resend: support@resend.com

### ¿Puedo usar un subdominio?

Sí, puedes verificar subdominios (ej: mail.ideally.com.mx), pero generalmente es mejor verificar el dominio principal y luego usar cualquier dirección de ese dominio.

## Recursos adicionales

- [Documentación de Resend](https://resend.com/docs)
- [Guía de verificación de dominio](https://resend.com/docs/dashboard/domains/introduction)
- [Status de Resend](https://resend.com/status)
- [Soporte de Resend](mailto:support@resend.com)
