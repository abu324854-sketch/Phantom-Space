// Shaxsiy bulut serveri (WebDAV).
// Fayllar DATA_DIR papkasida saqlanadi. Kirish: Basic auth (login/parol).
const fs = require('fs');
const path = require('path');
const webdav = require('webdav-server').v2;

const PORT = parseInt(process.env.PORT || '8080', 10);
const DATA_DIR = path.resolve(process.env.DATA_DIR || './data');
const USERNAME = process.env.CLOUD_USER || 'admin';
const PASSWORD = process.env.CLOUD_PASSWORD;

if (!PASSWORD || PASSWORD.length < 12) {
  console.error('XATO: CLOUD_PASSWORD o\'zgaruvchisini kamida 12 belgili qilib bering.');
  process.exit(1);
}

fs.mkdirSync(DATA_DIR, { recursive: true });

const userManager = new webdav.SimpleUserManager();
const user = userManager.addUser(USERNAME, PASSWORD, true);

const privilegeManager = new webdav.SimplePathPrivilegeManager();
privilegeManager.setRights(user, '/', ['all']);

const server = new webdav.WebDAVServer({
  port: PORT,
  httpAuthentication: new webdav.HTTPBasicAuthentication(userManager, 'PCloud'),
  privilegeManager,
  requireAuthentification: true,
  maxRequestDepth: Infinity
});

server.setFileSystem('/', new webdav.PhysicalFileSystem(DATA_DIR), (success) => {
  if (!success) {
    console.error('Fayl tizimini ulashda xato');
    process.exit(1);
  }
  server.start(() => {
    console.log(`PCloud ishga tushdi: port ${PORT}, papka ${DATA_DIR}`);
  });
});
