import Tubo
import TipoMovimiento
import Deposito
from datetime import date

class Registro:
    def __init__(self):
        self.id = -1
        self.fecha = date()
        self.tubo = Tubo()
        self.cantidad = -1
        self.tipoMovimiento = TipoMovimiento()
        self.depositoOrigen = Deposito()
        self.depositoDestino = Deposito()
        self.observacion1 = ""
        self.observacion2 = ""