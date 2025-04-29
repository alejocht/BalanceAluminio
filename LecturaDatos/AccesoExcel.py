import os
import pandas as pd
from tkinter import Tk, filedialog, messagebox

class AccesoExcel:
    def __init__(self):
        self.df = []
        self.rutaArchivo = ""

    def elegir_archivo(self):
        try:
            root = Tk()
            root.withdraw()
            ruta = filedialog.askopenfilename(title="Selecciona Archivo")
            self.rutaArchivo = ruta
        except Exception as e:
            messagebox.showwarning("Error al Seleccionar Archivo", f"{e}")

    def cargar(self):
        try:
            self.df = pd.read_excel(self.rutaArchivo)
        except Exception as e:
            messagebox.showwarning("Error al leer Archivo", f"{e}")

    def imprimir_por_pantalla(self):
        print(self.df)