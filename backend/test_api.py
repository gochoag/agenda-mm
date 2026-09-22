import unittest
import json
import os
import sys

# Asegurar que el directorio raíz esté en sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Usar base de datos temporal de prueba
os.environ['DATABASE_PATH'] = os.path.abspath(os.path.join(os.path.dirname(__file__), 'test_agenda.db'))

from backend.app import create_app
from backend.models import db, User, CalendarEvent, StickyNote

class AgendaApiTestCase(unittest.TestCase):
    def setUp(self):
        self.app = create_app()
        self.client = self.app.test_client()
        self.ctx = self.app.app_context()
        self.ctx.push()
        db.create_all()

        # Crear únicamente el usuario admin de prueba (sin siembra automática)
        admin = User(username='admin', role='admin')
        admin.set_password('admin123')
        db.session.add(admin)
        db.session.commit()

    def tearDown(self):
        db.session.remove()
        db.drop_all()
        self.ctx.pop()
        test_db = os.environ.get('DATABASE_PATH')
        if test_db and os.path.exists(test_db):
            try:
                os.remove(test_db)
            except Exception:
                pass

    def _login(self, username, password):
        res = self.client.post('/api/auth/login', json={'username': username, 'password': password})
        self.assertEqual(res.status_code, 200, f"Login failed for {username}: {res.get_json()}")
        data = res.get_json()
        return data['token'], data['user']

    def test_full_workflow(self):
        print("\n--- Ejecutando pruebas de Backend y Endpoints ---")

        # 1. Healthcheck
        res = self.client.get('/api/health')
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.get_json()['status'], 'ok')
        print("[OK] Healthcheck exitoso")

        # 2. Login Admin
        admin_token, admin_user = self._login('admin', 'admin123')
        self.assertEqual(admin_user['role'], 'admin')
        print("[OK] Login Admin exitoso")
        admin_headers = {'Authorization': f'Bearer {admin_token}'}

        # 3. Admin crea CoAdmin (soporta múltiples CoAdmins)
        res = self.client.post('/api/admin/users', headers=admin_headers, json={
            'username': 'coadmin',
            'password': 'coadmin123',
            'role': 'coadmin'
        })
        self.assertEqual(res.status_code, 201)
        coadmin_user = res.get_json()['user']
        print("[OK] Admin crea usuario CoAdmin exitosamente")

        # Admin crea un segundo CoAdmin (validar que pueden ser varios)
        res = self.client.post('/api/admin/users', headers=admin_headers, json={
            'username': 'coadmin_sucursal2',
            'password': 'password123',
            'role': 'coadmin'
        })
        self.assertEqual(res.status_code, 201)
        print("[OK] Admin crea múltiples CoAdmins (coadmin_sucursal2) validado")

        # Login CoAdmin
        coadmin_token, coadmin_user = self._login('coadmin', 'coadmin123')
        self.assertEqual(coadmin_user['role'], 'coadmin')
        print("[OK] Login CoAdmin exitoso")

        # 4. Credenciales inválidas
        res = self.client.post('/api/auth/login', json={'username': 'admin', 'password': 'wrongpassword'})
        self.assertEqual(res.status_code, 401)
        print("[OK] Protección de contraseña encriptada verificada")

        # 4. Creación de Notas Adhesivas
        # CoAdmin crea una nota (ejemplo de notas reales con cifras)
        coadmin_headers = {'Authorization': f'Bearer {coadmin_token}'}
        res = self.client.post('/api/notes', headers=coadmin_headers, json={
            'content': "Gasto 126.5 Agroprospera\n90$ costo viaje\n80$ carro\nSaldo: 2227",
            'color': '#FFF59D',
            'font_family': 'mono'
        })
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.get_json()['note']['font_family'], 'mono')
        coadmin_note_id = res.get_json()['note']['id']

        # Admin crea su nota
        admin_headers = {'Authorization': f'Bearer {admin_token}'}
        res = self.client.post('/api/notes', headers=admin_headers, json={
            'content': "Silver 1800\nSaldo pendiente 410$ - cancela",
            'color': '#FFCDD2',
            'font_family': 'casual',
            'is_pinned': True
        })
        self.assertEqual(res.status_code, 201)
        self.assertEqual(res.get_json()['note']['font_family'], 'casual')

        # 5. Verificación de permisos y visibilidad de Notas
        # CoAdmin solo debe ver 1 nota (la suya)
        res = self.client.get('/api/notes', headers=coadmin_headers)
        coadmin_notes = res.get_json()['notes']
        self.assertEqual(len(coadmin_notes), 1)
        self.assertEqual(coadmin_notes[0]['id'], coadmin_note_id)
        print("[OK] CoAdmin solo ve sus notas (Aislamiento de datos validado)")

        # Admin debe ver ambas notas
        res = self.client.get('/api/notes', headers=admin_headers)
        admin_notes = res.get_json()['notes']
        self.assertEqual(len(admin_notes), 2)
        print("[OK] Admin tiene visibilidad total de notas")

        # 6. Eventos de Calendario
        # CoAdmin crea evento
        res = self.client.post('/api/calendar', headers=coadmin_headers, json={
            'detail': 'Entrega de lote 2',
            'event_date': '2026-09-25 10:00',
            'status': 'pendiente'
        })
        self.assertEqual(res.status_code, 201)
        coadmin_event_id = res.get_json()['event']['id']

        # Admin crea evento
        res = self.client.post('/api/calendar', headers=admin_headers, json={
            'detail': 'Reunión de balance mensual',
            'event_date': '2026-09-30 15:00',
            'status': 'pendiente'
        })
        self.assertEqual(res.status_code, 201)

        # CoAdmin solo ve su evento
        res = self.client.get('/api/calendar', headers=coadmin_headers)
        self.assertEqual(len(res.get_json()['events']), 1)

        # Admin ve ambos eventos
        res = self.client.get('/api/calendar', headers=admin_headers)
        self.assertEqual(len(res.get_json()['events']), 2)
        print("[OK] Visibilidad de eventos de calendario validada")

        # CoAdmin actualiza estado a completado
        res = self.client.put(f'/api/calendar/{coadmin_event_id}', headers=coadmin_headers, json={
            'status': 'completado'
        })
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.get_json()['event']['status'], 'completado')
        print("[OK] Actualización de estado en calendario validada")

        # 7. Control de Acceso a Endpoints de Admin
        # CoAdmin intenta acceder a /api/admin/users -> debe dar 403 Forbidden
        res = self.client.get('/api/admin/users', headers=coadmin_headers)
        self.assertEqual(res.status_code, 403)
        print("[OK] CoAdmin bloqueado correctamente en rutas de administración (403 Forbidden)")

        # 8. Admin cambia la contraseña de CoAdmin
        res = self.client.put(f'/api/admin/users/{coadmin_user["id"]}/password', headers=admin_headers, json={
            'new_password': 'nueva_clave_coadmin_2026'
        })
        self.assertEqual(res.status_code, 200)

        # Verificar que la antigua clave ya no funciona
        res = self.client.post('/api/auth/login', json={'username': 'coadmin', 'password': 'coadmin123'})
        self.assertEqual(res.status_code, 401)

        # Verificar que la nueva clave sí funciona
        new_coadmin_token, _ = self._login('coadmin', 'nueva_clave_coadmin_2026')
        self.assertTrue(bool(new_coadmin_token))
        print("[OK] Cambio de contraseña de CoAdmin por parte de Admin validado")

        # 9. Backup y Restauración Limpia (JSON)
        # Exportar backup
        res = self.client.get('/api/admin/backup', headers=admin_headers)
        self.assertEqual(res.status_code, 200)
        backup_json = res.get_json()
        self.assertEqual(len(backup_json['users']), 3) # admin + coadmin + coadmin_sucursal2
        self.assertEqual(len(backup_json['calendar_events']), 2)
        self.assertEqual(len(backup_json['sticky_notes']), 2)
        print("[OK] Exportación de backup JSON completada con éxito")

        # Insertar un registro sucio / extra que debe desaparecer al restaurar
        self.client.post('/api/notes', headers=admin_headers, json={
            'content': 'Nota basura temporal para prueba de restauración',
            'color': '#B3E5FC'
        })
        res = self.client.get('/api/notes', headers=admin_headers)
        self.assertEqual(len(res.get_json()['notes']), 3)

        # Ejecutar Restauración Limpia usando el backup previo
        res = self.client.post('/api/admin/restore', headers=admin_headers, json=backup_json)
        self.assertEqual(res.status_code, 200)
        print("[OK] Endpoint de restauración ejecutado exitosamente")

        # Verificar que la BD quedó limpia exactamente con los 2 registros del backup (la nota basura desapareció)
        res = self.client.get('/api/notes', headers=admin_headers)
        restored_notes = res.get_json()['notes']
        self.assertEqual(len(restored_notes), 2)

        res = self.client.get('/api/calendar', headers=admin_headers)
        restored_events = res.get_json()['events']
        self.assertEqual(len(restored_events), 2)
        print("[OK] Restauración limpia validada al 100% (cero duplicados ni residuos)")

        print("--- Todas las pruebas del Backend finalizaron con ÉXITO ---\n")


if __name__ == '__main__':
    unittest.main()
