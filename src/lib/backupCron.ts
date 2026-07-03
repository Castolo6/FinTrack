import cron from 'node-cron';
import { google } from 'googleapis';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { db } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// REEMPLAZA ESTO CON EL ID DE TU ARCHIVO EN GOOGLE DRIVE
// (El ID es lo que aparece en la URL de tu archivo en Drive)
const DRIVE_FILE_ID = '1QYjRPB72ElMoatXkEkgLuBHBC9gQMjiE';

const credentialsPath = path.resolve(process.cwd(), 'google-credentials.json');

// Autorización para Google Drive
const auth = new google.auth.GoogleAuth({
  keyFile: credentialsPath,
  scopes: ['https://www.googleapis.com/auth/drive'],
});

const drive = google.drive({ version: 'v3', auth });

/**
 * Genera un JSON con toda la información de la base de datos SQLite
 */
function generateDatabaseJson() {
  const data: any = {};
  // Agregar budgets que faltaba, más las entidades nuevas
  const tables = ['users', 'accounts', 'categories', 'transactions', 'budgets', 'saving_goals', 'investments', 'credits'];
  
  for (const table of tables) {
    try {
      data[table] = db.prepare(`SELECT * FROM ${table}`).all();
    } catch (e) {
      console.warn(`No se pudo leer la tabla ${table}`);
    }
  }
  
  const backupData = {
    version: '1.0.0',
    timestamp: Date.now(),
    data: data
  };
  
  return JSON.stringify(backupData, null, 2);
}

/**
 * Función principal: Extrae la DB y la sube a Drive
 */
async function backupToDrive() {
  try {
    console.log('Iniciando respaldo automático a Google Drive...');
    
    if (!fs.existsSync(credentialsPath)) {
      console.error('❌ Error: No se encontró el archivo google-credentials.json en la raíz del proyecto.');
      return;
    }
    
    if (DRIVE_FILE_ID === 'AQUI_EL_ID_DEL_ARCHIVO_EN_DRIVE') {
      console.error('❌ Error: No has configurado el DRIVE_FILE_ID en src/lib/backupCron.ts');
      return;
    }
    
    // Generar JSON
    const jsonData = generateDatabaseJson();
    
    // Configurar nombre de archivo con timestamp para igualar el formato de exportación local
    const timestamp = Date.now();
    const fileName = `fintrack_backup_${timestamp}.json`;
    
    // Crear archivo temporal
    const tempFilePath = path.resolve(process.cwd(), fileName);
    fs.writeFileSync(tempFilePath, jsonData);
    
    // Actualizar el archivo existente en Google Drive y renombrarlo al formato correcto
    const media = {
      mimeType: 'application/json',
      body: fs.createReadStream(tempFilePath)
    };
    
    const response = await drive.files.update({
      fileId: DRIVE_FILE_ID,
      requestBody: {
        name: fileName // Esto renombrará el archivo de texto en Google Drive a .json
      },
      media: media,
      fields: 'id, name'
    });
    
    console.log(`✅ Respaldo subido y renombrado a ${fileName} en Drive! File ID: ${response.data.id}`);
    
    // Eliminar archivo temporal
    fs.unlinkSync(tempFilePath);
    
  } catch (error: any) {
    console.error('❌ Error al respaldar en Google Drive:', error.message);
  }
}

// Programar tarea para las 23:00 todos los días
// Cambia 'America/Santiago' por tu zona horaria si es distinta
cron.schedule('0 23 * * *', () => {
  backupToDrive();
}, {
  scheduled: true,
  timezone: "America/Santiago"
});

console.log('🕒 Módulo de respaldos a Google Drive iniciado (Programado para las 23:00).');

// Descomentar la siguiente línea si quieres que haga un respaldo de prueba apenas inicie:
// backupToDrive();
