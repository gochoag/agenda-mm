import sys
import os

# Ruta donde estará alojado el proyecto en PythonAnywhere
# Ejemplo: /home/tu_usuario/agenda-mm
project_home = os.path.dirname(os.path.abspath(__file__))
if project_home not in sys.path:
    sys.path.insert(0, os.path.dirname(project_home))

from backend.app import app as application
