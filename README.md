# Clínica Valencia — App standalone (estática)

Rebuild estático del sistema “Sistema Clínica Valencia” como una sola página
(`index.html` + Supabase JS por CDN), siguiendo el patrón FisioSimula:
sin servidor propio, sin contraseñas en el código, datos en Supabase.

## Datos de la clínica (no inventar más)

- Hospital Clínica Valencia, Gabriel García Moreno y Aurora Estrada, Guayaquil 090301
- WhatsApp 0980795876 / 0999897742 · Teléfono 04-502-4739
- Correo clinikvalencia@gmail.com · Facebook @CLINIKVALENCIA
- Dr. Jorge Valencia · Expertos oncológicos · Previa cita

## 1. Crear el proyecto Supabase

1. Entra a https://supabase.com/dashboard y crea un proyecto nuevo
   (nombre sugerido: `clinica-valencia`; región cercana, ej. São Paulo).
2. Espera a que el proyecto quede **Healthy**.
3. En **Authentication → Providers → Email**, deja habilitado el email
   (es lo que usa la app; no hace falta confirmar correo para probar,
   pero se recomienda activar la confirmación en producción).

## 2. Crear las tablas (una sola vez)

1. En el proyecto: **SQL Editor → New query**.
2. Pega **todo** el contenido de `supabase-schema.sql` y pulsa **Run**.
3. Eso crea las 21 tablas, el RLS en todas, la función `is_doctor()` y
   siembra las 38 especialidades/servicios con precio 0 (por confirmar).

## 3. Copiar la URL y la clave anon en la app

1. En el proyecto: **Settings → API**.
2. Copia la **Project URL** y la clave **anon / public** (la que dice
   `anon public`).
3. Abre la app, pulsa **“Configurar Supabase”** y pega esos dos valores.
   Quedan guardados solo en el `localStorage` de ese navegador.
4. **⛔ NUNCA pegues la clave `service_role`.** La app la detecta y la
   rechaza. La `service_role` no debe salir nunca del servidor.

## 4. Crear la cuenta del Dr. Valencia

1. En la app, baja hasta **“Crear cuenta de paciente”** — no, esa es para
   pacientes. El doctor entra por el **inicio de sesión** con su usuario:
   escribe `dr.valencia` (también se acepta `Dr. Valencia` o
   `dr valencia`) y su contraseña.
2. La primera vez, el doctor debe registrarse: usa el registro de
   Supabase Auth desde la app con el usuario `dr.valencia` y luego, en
   Supabase (**Authentication → Users**), verifica que su fila en
   `profiles` tenga `role = 'doctor'`. La forma más simple: crea la
   cuenta de Auth y edita su fila en `profiles` (tabla) poniendo
   `role='doctor'`, `full_name='Dr. Jorge Valencia'`,
   `username='dr.valencia'`.
3. Las enfermeras las crea el doctor desde su panel **Accesos** (nombre +
   usuario; ella pone su contraseña y debe cambiarla en el primer ingreso).

> Nota: los pacientes se crean solos desde “Crear cuenta de paciente”
> (nombre, WhatsApp, fecha de nacimiento + su propia contraseña).
> Su correo interno es `wa<WhatsApp>@pacientes.clinicavalencia.local`
> y el del personal `<usuario>@staff.clinicavalencia.local`.
> Son correos sintéticos solo para el login; nadie recibe correo ahí.

## 5. Publicar en GitHub Pages

1. Sube esta carpeta a un repositorio de GitHub (rama `main`, raíz).
2. **Settings → Pages → Source: Deploy from a branch → main / (root)**.
3. Abre la URL `https://<usuario>.github.io/<repo>/`.
4. En la app, configura Supabase (paso 3) en ese navegador.
   Cada navegador/dispositivo debe configurarlo una vez.

## ⚠️ Aviso del plan gratuito de Supabase

El plan gratuito **pausa el proyecto tras 7 días sin actividad**.
Si la app deja de cargar datos, entra al dashboard de Supabase y
reactiva el proyecto (botón **Restore / Resume**); los datos no se
pierden. Para uso diario real, conviene el plan de pago o entrar al
menos una vez por semana.

## Archivos

| Archivo | Qué es |
|---|---|
| `index.html` | La aplicación completa (landing, login único, paneles de paciente, doctor y enfermera, caso EJEMPLO) |
| `supabase-schema.sql` | Tablas + RLS + 38 servicios (pegar una vez en el SQL Editor) |
| `assets/logo-oficial.jpg` | Logo oficial de la clínica (copia exacta, no recreado) |

## Exámenes: solo metadatos en v1

En esta versión los exámenes se **registran** (tipo, nombre de archivo
y notas), pero el archivo binario **no se sube** a Supabase Storage:
no hace falta crear ningún bucket. El doctor ve el resumen preliminar
de IA con su nota obligatoria y lo aprueba, corrige o rechaza. Si más
adelante se quiere subir el PDF/imagen real, hay que crear un bucket
privado en Storage y ampliar la app.

## Nota de IA (obligatoria, siempre visible)

> “Este es solo un análisis preliminar generado por IA, NO es un
> diagnóstico. Falta verificar por su médico. Consulte siempre con el
> Dr. Jorge Valencia antes de tomar cualquier decisión.”

La IA nunca da un diagnóstico definitivo, nunca receta y nunca promete
una cura.

## Verificación realizada

- [x] `index.html` se abrió localmente: la landing muestra el camino
      del paciente (Entrada · Consulta → … → ¡Alta! Ya estoy bien),
      la parrilla de 38 especialidades y el login único al final.
- [x] Lógica de login revisada: identificador de paciente (WhatsApp) o
      de personal (usuario, con `dr.valencia` normalizado) → correo
      sintético → Supabase Auth → rol desde `profiles`.
- [x] Flujos principales revisados en código: agendar en 4 pasos con
      horas reales ocupadas, historia clínica con IMC automático,
      plan perioperatorio, entrega de turno, alta con PDF imprimible
      y exportación CSV de ingresos/citas/exámenes.
- [x] Sin contraseñas en los archivos: `grep -ri "password.*=\|service_role" index.html supabase-schema.sql README.md`
      no muestra ninguna contraseña ni clave real (solo la palabra
      `service_role` en las advertencias de no usarla).
- [x] Sintaxis JS verificada con `node --check` en los dos bloques
      `<script>` de `index.html`.
- [x] El caso EJEMPLO es solo en memoria y está marcado EJEMPLO/DEMO;
      no se guarda en Supabase.
- [ ] **No verificado contra un proyecto Supabase real**: no se creó
      ningún proyecto ni se hizo login de prueba (el parent gestiona
      repo/push y el doctor configura Supabase). Antes de usar con
      pacientes reales, probar: crear proyecto, pegar el SQL, crear
      la cuenta `dr.valencia`, registrar un paciente y agendar una cita.
