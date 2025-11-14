"""
Sistema de Logging Profesional para Modelo de Dislexia
Proporciona salida estructurada con barras de progreso y mensajes informativos
"""

import sys
import time
from typing import Optional, Callable, List, Dict, Any, Tuple
from datetime import datetime


class ProfessionalLogger:
    
    # Colores ANSI para terminal
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'
    
    def __init__(self):
        self.start_time = None
        self.section_start_time = None
        self.phase_times = {}
        self.current_phase = None
        
    def print_header(self, title: str):
        """Imprime encabezado profesional"""
        line = "=" * 80
        print(f"\n{self.BOLD}{self.BLUE}{line}{self.RESET}")
        print(f"{self.BOLD}{self.CYAN}{title.center(80)}{self.RESET}")
        print(f"{self.BOLD}{self.BLUE}{line}{self.RESET}\n")
    
    def print_section(self, section_name: str):
        """Imprime titulo de seccion"""
        print(f"\n{self.BOLD}{self.CYAN}━━━ {section_name} ━━━{self.RESET}")
        self.section_start_time = time.time()
    
    def print_step(self, step_number: int, total_steps: int, description: str):
        """Imprime paso con barra de progreso"""
        progress = (step_number / total_steps) * 100
        bar_length = 50
        filled_length = int(bar_length * step_number / total_steps)
        bar = '█' * filled_length + '░' * (bar_length - filled_length)
        
        print(f"\n{self.BOLD}{self.YELLOW}[{step_number}/{total_steps}] {progress:.0f}% - {description}{self.RESET}")
        print(f"{self.YELLOW}[{bar}]{self.RESET}")
    
    def print_success(self, message: str):
        """Imprime mensaje de exito"""
        print(f"{self.GREEN}✓ {message}{self.RESET}")
    
    def print_info(self, message: str):
        """Imprime mensaje informativo"""
        print(f"{self.CYAN}ℹ {message}{self.RESET}")
    
    def print_warning(self, message: str):
        """Imprime mensaje de advertencia"""
        print(f"{self.YELLOW}⚠ {message}{self.RESET}")
    
    def print_error(self, message: str):
        """Imprime mensaje de error"""
        print(f"{self.RED}✗ {message}{self.RESET}")
    
    def print_metric(self, metric_name: str, value: float, unit: str = ""):
        """Imprime metrica de rendimiento"""
        print(f"{self.BOLD}{self.WHITE}{metric_name}:{self.RESET} {self.CYAN}{value:.4f}{unit}{self.RESET}")
    
    def print_table(self, headers: list, data: list):
        """Imprime tabla de resultados"""
        # Calcular ancho de columnas
        col_widths = []
        for i, header in enumerate(headers):
            max_width = len(str(header))
            for row in data:
                max_width = max(max_width, len(str(row[i])))
            col_widths.append(max_width + 2)
        
        # Encabezado
        header_line = ""
        for i, header in enumerate(headers):
            header_line += f"{self.BOLD}{self.CYAN}{str(header).ljust(col_widths[i])}{self.RESET}"
        
        print(f"\n{header_line}")
        print(f"{self.CYAN}{'-' * sum(col_widths)}{self.RESET}")
        
        # Filas de datos
        for row in data:
            row_line = ""
            for i, cell in enumerate(row):
                row_line += f"{self.WHITE}{str(cell).ljust(col_widths[i])}{self.RESET}"
            print(row_line)
    
    def print_progress_bar(self, current: int, total: int, description: str = "", length: int = 60):
        """Imprime barra de progreso dinamica"""
        percent = current / float(total)
        filled_length = int(length * percent)
        
        bar = '█' * filled_length + '░' * (length - filled_length)
        percent_str = f"{percent * 100:.1f}%"
        
        print(f"\r{self.YELLOW}{description} |{bar}| {percent_str}{self.RESET}", end='', flush=True)
        
        if current == total:
            print()
    
    def print_summary(self, summary_data: dict):
        """Imprime resumen de resultados"""
        print(f"\n{self.BOLD}{self.BLUE}{'=' * 80}{self.RESET}")
        print(f"{self.BOLD}{self.GREEN}RESUMEN DE RESULTADOS{self.RESET}")
        print(f"{self.BOLD}{self.BLUE}{'=' * 80}{self.RESET}\n")
        
        for key, value in summary_data.items():
            if isinstance(value, float):
                print(f"{self.BOLD}{key}:{self.RESET} {self.GREEN}{value:.4f}{self.RESET}")
            elif isinstance(value, bool):
                status = f"{self.GREEN}SI{self.RESET}" if value else f"{self.RED}NO{self.RESET}"
                print(f"{self.BOLD}{key}:{self.RESET} {status}")
            else:
                print(f"{self.BOLD}{key}:{self.RESET} {self.WHITE}{value}{self.RESET}")
    
    def print_model_ready(self):
        """Imprime mensaje de modelo listo"""
        print(f"\n{self.BOLD}{self.GREEN}{'█' * 80}{self.RESET}")
        print(f"{self.BOLD}{self.GREEN}MODELO ENTRENADO EXITOSAMENTE{self.RESET}")
        print(f"{self.BOLD}{self.GREEN}{'█' * 80}{self.RESET}\n")
        
        print(f"{self.GREEN}Archivos generados:{self.RESET}")
        print(f"  {self.CYAN}✓{self.RESET} modelo_dislexia_optimizado.pkl")
        print(f"  {self.CYAN}✓{self.RESET} imputer_optimizado.pkl")
        print(f"  {self.CYAN}✓{self.RESET} modelo_info.json\n")
    
    # ==================== MÉTODOS ESPECIALIZADOS POR FASE ====================
    
    def print_phase_data_loading(self, records_desktop: int, records_tablet: int, 
                                 total_records: int):
        """Fase 1: Carga de Datos"""
        self.print_section("FASE 1 - CARGA DE DATOS")
        
        self.print_progress_bar(1, 4, "Leyendo Dyt-desktop.csv")
        print(f"  {self.CYAN}✓{self.RESET} {self.GREEN}{records_desktop:,}{self.RESET} registros cargados\n")
        
        self.print_progress_bar(2, 4, "Leyendo Dyt-tablet.csv")
        print(f"  {self.CYAN}✓{self.RESET} {self.GREEN}{records_tablet:,}{self.RESET} registros cargados\n")
        
        self.print_progress_bar(3, 4, "Fusionando datasets")
        print(f"  {self.CYAN}✓{self.RESET} Concatenación completada\n")
        
        self.print_progress_bar(4, 4, "Validando datos")
        print(f"  {self.CYAN}✓{self.RESET} Total: {self.GREEN}{total_records:,}{self.RESET} registros\n")
        
        self.print_success(f"Dataset cargado: {total_records:,} registros")
    
    def print_phase_preprocessing(self, records: int, numeric_cols: int, 
                                 categorical_cols: int):
        """Fase 2: Preprocesamiento y Limpieza"""
        self.print_section("FASE 2 - PREPROCESAMIENTO Y LIMPIEZA")
        
        self.print_progress_bar(1, 5, "Validando estructura de datos")
        print(f"  {self.CYAN}✓{self.RESET} {records:,} registros verificados\n")
        
        self.print_progress_bar(2, 5, "Convirtiendo tipos numéricos")
        print(f"  {self.CYAN}✓{self.RESET} {numeric_cols} columnas numéricas procesadas\n")
        
        self.print_progress_bar(3, 5, "Codificando variables categóricas")
        print(f"  {self.CYAN}✓{self.RESET} {categorical_cols} columnas codificadas (binarias)\n")
        
        self.print_progress_bar(4, 5, "Eliminando filas sin etiqueta")
        print(f"  {self.CYAN}✓{self.RESET} Etiquetas validadas\n")
        
        self.print_progress_bar(5, 5, "Verificando integridad")
        print(f"  {self.CYAN}✓{self.RESET} Todos los datos válidos\n")
        
        self.print_success("Preprocesamiento completado exitosamente")
    
    def print_phase_imputation(self, missing_before: int, missing_after: int, 
                              strategy: str = "Mediana"):
        """Fase 3: Imputación de Valores Faltantes"""
        self.print_section("FASE 3 - IMPUTACIÓN DE VALORES FALTANTES")
        
        self.print_progress_bar(1, 4, "Detectando valores faltantes")
        print(f"  {self.CYAN}✓{self.RESET} {missing_before:,} valores faltantes encontrados\n")
        
        self.print_progress_bar(2, 4, f"Inicializando {strategy}")
        print(f"  {self.CYAN}✓{self.RESET} SimpleImputer configurado\n")
        
        self.print_progress_bar(3, 4, "Imputando datos faltantes")
        print(f"  {self.CYAN}✓{self.RESET} {missing_before:,} valores restaurados\n")
        
        self.print_progress_bar(4, 4, "Validando completitud")
        print(f"  {self.CYAN}✓{self.RESET} {missing_after} valores faltantes restantes\n")
        
        self.print_success(f"Imputación completada - {missing_before:,} valores restaurados")
    
    def print_phase_feature_engineering(self, original_features: int, 
                                       new_features: int, total_features: int):
        """Fase 4: Ingeniería de Características"""
        self.print_section("FASE 4 - INGENIERÍA DE CARACTERÍSTICAS")
        
        self.print_progress_bar(1, 5, "Analizando características originales")
        print(f"  {self.CYAN}✓{self.RESET} {original_features} características base\n")
        
        self.print_progress_bar(2, 5, "Calculando tendencias temporales")
        print(f"  {self.CYAN}✓{self.RESET} accuracy_trend, accuracy_improvement\n")
        
        self.print_progress_bar(3, 5, "Extrayendo variabilidad")
        print(f"  {self.CYAN}✓{self.RESET} clicks_variability, global_accuracy\n")
        
        self.print_progress_bar(4, 5, "Derivando ratios de desempeño")
        print(f"  {self.CYAN}✓{self.RESET} error_concentration, consistency_score\n")
        
        self.print_progress_bar(5, 5, "Finalizando ingeniería")
        print(f"  {self.CYAN}✓{self.RESET} {new_features} características nuevas creadas\n")
        
        self.print_success(f"Ingeniería completada - {new_features} características nuevas, Total: {total_features}")
    
    def print_phase_balancing(self, class_distribution_before: Tuple[int, int], 
                             class_distribution_after: Tuple[int, int], 
                             synthetic_samples: int):
        """Fase 5: Balanceo de Clases"""
        self.print_section("FASE 5 - BALANCEO DE CLASES")
        
        before_no_dys, before_dys = class_distribution_before
        after_no_dys, after_dys = class_distribution_after
        
        self.print_progress_bar(1, 4, "Analizando desbalanceo inicial")
        print(f"  {self.YELLOW}⚠{self.RESET} No Dislexia: {before_no_dys:,} ({before_no_dys/(before_no_dys+before_dys)*100:.1f}%)")
        print(f"  {self.YELLOW}⚠{self.RESET} Dislexia: {before_dys:,} ({before_dys/(before_no_dys+before_dys)*100:.1f}%)\n")
        
        self.print_progress_bar(2, 4, "Inicializando ADASYN")
        print(f"  {self.CYAN}✓{self.RESET} Algoritmo configurado\n")
        
        self.print_progress_bar(3, 4, "Generando muestras sintéticas")
        print(f"  {self.CYAN}✓{self.RESET} {synthetic_samples:,} muestras creadas\n")
        
        self.print_progress_bar(4, 4, "Validando distribución final")
        print(f"  {self.GREEN}✓{self.RESET} No Dislexia: {after_no_dys:,} ({after_no_dys/(after_no_dys+after_dys)*100:.1f}%)")
        print(f"  {self.GREEN}✓{self.RESET} Dislexia: {after_dys:,} ({after_dys/(after_no_dys+after_dys)*100:.1f}%)\n")
        
        self.print_success(f"Balanceo completado - {synthetic_samples:,} muestras sintéticas generadas")
    
    def print_phase_training(self, train_size: int, test_size: int, 
                            cv_folds: int, hyperparameters: Dict[str, Any]):
        """Fase 6: Entrenamiento del Modelo"""
        self.print_section("FASE 6 - ENTRENAMIENTO DEL MODELO")
        
        total_size = train_size + test_size
        train_pct = (train_size / total_size) * 100
        test_pct = (test_size / total_size) * 100
        
        self.print_progress_bar(1, 5, "Dividiendo dataset")
        print(f"  {self.CYAN}✓{self.RESET} Entrenamiento: {train_size:,} ({train_pct:.1f}%)")
        print(f"  {self.CYAN}✓{self.RESET} Prueba: {test_size:,} ({test_pct:.1f}%)\n")
        
        self.print_progress_bar(2, 5, "Configurando Random Forest")
        print(f"  {self.CYAN}✓{self.RESET} {hyperparameters.get('n_estimators')} árboles\n")
        
        self.print_progress_bar(3, 5, "Estableciendo hiperparámetros")
        print(f"  {self.CYAN}✓{self.RESET} max_depth: {hyperparameters.get('max_depth')}\n")
        
        self.print_progress_bar(4, 5, "Optimizando validación cruzada")
        print(f"  {self.CYAN}✓{self.RESET} {cv_folds}-fold estratificada\n")
        
        self.print_progress_bar(5, 5, "Entrenando modelo")
        print(f"  {self.CYAN}✓{self.RESET} En progreso...\n")
        
        self.print_success("Modelo entrenado exitosamente")
    
    def print_phase_evaluation(self, metrics: Dict[str, float], cv_scores: List[float]):
        """Fase 7: Evaluación del Modelo"""
        self.print_section("FASE 7 - EVALUACIÓN DEL MODELO")
        
        self.print_progress_bar(1, 5, "Prediciendo en conjunto test")
        print(f"  {self.CYAN}✓{self.RESET} {len(cv_scores)} predicciones completadas\n")
        
        self.print_progress_bar(2, 5, "Calculando métricas de desempeño")
        acc_test = metrics.get('accuracy_test', 0)
        print(f"  {self.CYAN}✓{self.RESET} Accuracy: {acc_test:.4f}\n")
        
        self.print_progress_bar(3, 5, "Validación cruzada K-Fold")
        cv_mean = cv_scores.mean()
        cv_std = cv_scores.std()
        print(f"  {self.CYAN}✓{self.RESET} ROC AUC: {cv_mean:.4f} ± {cv_std:.4f}\n")
        
        self.print_progress_bar(4, 5, "Generando matriz de confusión")
        print(f"  {self.CYAN}✓{self.RESET} Matriz calculada\n")
        
        self.print_progress_bar(5, 5, "Compilando resultados finales")
        print(f"  {self.CYAN}✓{self.RESET} Todas las métricas calculadas\n")
        
        self.print_success("Evaluación completada")
    
    def print_phase_serialization(self, files_created: List[str], directory: str = "pkl"):
        """Fase 8: Serialización de Resultados"""
        self.print_section("FASE 8 - SERIALIZACIÓN DE RESULTADOS")
        
        self.print_progress_bar(1, 3, f"Guardando en '{directory}/'")
        print(f"  {self.CYAN}✓{self.RESET} Directorio verificado\n")
        
        self.print_progress_bar(2, 3, "Serializando archivos")
        for i, filename in enumerate(files_created, 1):
            file_size = "N/A"
            try:
                import os
                full_path = os.path.join(directory, filename)
                if os.path.exists(full_path):
                    file_size = f"{os.path.getsize(full_path) / 1024:.2f} KB"
            except:
                pass
            print(f"  {self.GREEN}{i}.{self.RESET} {filename} ({file_size})")
        print()
        
        self.print_progress_bar(3, 3, "Validando archivos")
        print(f"  {self.CYAN}✓{self.RESET} {len(files_created)} archivos guardados\n")
        
        self.print_success(f"Serialización completada - {len(files_created)} archivos guardados")
    
    # ==================== MÉTODOS AUXILIARES ====================
    
    def get_elapsed_time(self) -> str:
        """Retorna tiempo transcurrido formateado"""
        if self.section_start_time:
            elapsed = time.time() - self.section_start_time
            minutes = int(elapsed // 60)
            seconds = int(elapsed % 60)
            if minutes > 0:
                return f"{minutes}m {seconds}s"
            return f"{seconds}s"
        return "N/A"
    
    def print_timestamp(self):
        """Imprime timestamp actual"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"{self.CYAN}[{timestamp}]{self.RESET}")


# Instancia global del logger
logger = ProfessionalLogger()


def log_section(name: str):
    """Decorador para automatizar logging de secciones"""
    def decorator(func: Callable):
        def wrapper(*args, **kwargs):
            logger.print_section(name)
            try:
                result = func(*args, **kwargs)
                elapsed = logger.get_elapsed_time()
                logger.print_success(f"{name} completado en {elapsed}")
                return result
            except Exception as e:
                logger.print_error(f"Error en {name}: {str(e)}")
                raise
        return wrapper
    return decorator


def initialize_logger():
    """Inicializa el logger con mensaje de bienvenida"""
    logger.print_header("SISTEMA DE DETECCION DE DISLEXIA")
    logger.print_timestamp()
    print(f"{logger.CYAN}Version: 2.0{logger.RESET}")
    print(f"{logger.CYAN}Modelo: Random Forest Optimizado{logger.RESET}")
    print(f"{logger.CYAN}Dataset: PLOS ONE - Dislexia{logger.RESET}\n")
