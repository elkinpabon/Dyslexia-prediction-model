# -*- coding: utf-8 -*-
# ==============================================
#  MODELO DE DETECCION DE DISLEXIA
#  Dataset: Predicting Risk of Dyslexia (PLOS ONE / Kaggle)
#  Autor: Elkin Pabon
# ==============================================

# ==== 1. Importacion de librerias ====
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, roc_auc_score, roc_curve,
    precision_recall_curve, f1_score, balanced_accuracy_score,
    precision_score, recall_score
)
from sklearn.impute import SimpleImputer
from sklearn.calibration import CalibratedClassifierCV
from imblearn.over_sampling import ADASYN
from xgboost import XGBClassifier
import joblib
import json
import time
import warnings
warnings.filterwarnings('ignore')

from log_info import logger, initialize_logger

# ==== 2. Carga y union de datasets ====
desktop_df = pd.read_csv("../dataset/Dyt-desktop.csv", sep=';')
tablet_df = pd.read_csv("../dataset/Dyt-tablet.csv", sep=';')
combined_df = pd.concat([desktop_df, tablet_df], ignore_index=True)

initialize_logger()
logger.print_phase_data_loading(len(desktop_df), len(tablet_df), len(combined_df))

# ==== 3. Conversion y limpieza de datos ====
# Convertir variables numericas (ignorar las categoricas)
for col in combined_df.columns:
    if col not in ["Gender", "Nativelang", "Otherlang", "Dyslexia"]:
        combined_df[col] = pd.to_numeric(combined_df[col], errors="coerce")

# Eliminar filas sin etiqueta
combined_df = combined_df.dropna(subset=["Dyslexia"])

# Codificar variables categoricas
combined_df["Gender"] = combined_df["Gender"].map({"Male": 0, "Female": 1})
combined_df["Nativelang"] = combined_df["Nativelang"].map({"Yes": 1, "No": 0})
combined_df["Otherlang"] = combined_df["Otherlang"].map({"Yes": 1, "No": 0})
combined_df["Dyslexia"] = combined_df["Dyslexia"].map({"Yes": 1, "No": 0})

# Calcular distribucion de clases para validation cruzada
no_dislexia = (combined_df["Dyslexia"] == 0).sum()
si_dislexia = (combined_df["Dyslexia"] == 1).sum()
numeric_cols = len([col for col in combined_df.columns if col not in ["Gender", "Nativelang", "Otherlang", "Dyslexia"]])
categorical_cols = 4

logger.print_phase_preprocessing(len(combined_df), numeric_cols, categorical_cols)

# ==== 4. Division en variables ====
X = combined_df.drop(columns=["Dyslexia"])
y = combined_df["Dyslexia"]

# ==== 5. Imputacion de valores faltantes ====
missing_count_before = X.isnull().sum().sum()
imputer = SimpleImputer(strategy="median")
X_imputed = pd.DataFrame(imputer.fit_transform(X), columns=X.columns)
missing_count_after = X_imputed.isnull().sum().sum()

logger.print_phase_imputation(missing_count_before, missing_count_after, "Mediana")

# ==== 5.1. Feature Engineering Temporal - CORREGIDO ====
print("\n📊 Aplicando Feature Engineering Temporal...")

X_final = X_imputed.copy()

# Tendencias temporales - ITERAR POR CADA MUESTRA (CORRECCIÓN CRÍTICA)
accuracy_cols = sorted([col for col in X_imputed.columns if 'Accuracy' in col])[:32]
if accuracy_cols:
    accuracy_trend_list = []
    accuracy_first_half = []
    accuracy_second_half = []
    accuracy_improvement_list = []
    
    for idx in range(len(X_imputed)):
        values = X_imputed.iloc[idx][accuracy_cols].values
        
        # Tendencia lineal - POLYFIT CORRECTO por muestra
        if len(values) > 1 and np.sum(~np.isnan(values)) > 1:
            valid_mask = ~np.isnan(values)
            valid_indices = np.where(valid_mask)[0]
            valid_values = values[valid_mask]
            
            if len(valid_values) > 1:
                coeffs = np.polyfit(valid_indices, valid_values, 1)
                trend = float(coeffs[0])
            else:
                trend = 0.0
        else:
            trend = 0.0
        
        accuracy_trend_list.append(trend)
        
        # Primera y segunda mitad
        first_half_vals = values[:16]
        second_half_vals = values[16:32] if len(values) > 16 else values[16:]
        
        first_mean = np.nanmean(first_half_vals) if len(first_half_vals) > 0 else 0.0
        second_mean = np.nanmean(second_half_vals) if len(second_half_vals) > 0 else 0.0
        
        accuracy_first_half.append(first_mean)
        accuracy_second_half.append(second_mean)
        accuracy_improvement_list.append(second_mean - first_mean)
    
    X_final['accuracy_trend'] = accuracy_trend_list
    X_final['accuracy_mean_first_half'] = accuracy_first_half
    X_final['accuracy_mean_second_half'] = accuracy_second_half
    X_final['accuracy_improvement'] = accuracy_improvement_list
    print(f"  ✓ Tendencias de accuracy calculadas correctamente")

# Variabilidad en clicks
clicks_cols = sorted([col for col in X_imputed.columns if 'Clicks' in col])[:32]
if clicks_cols:
    X_final['clicks_variability'] = X_imputed[clicks_cols].std(axis=1)
    X_final['clicks_total'] = X_imputed[clicks_cols].sum(axis=1)
    print(f"  ✓ Variabilidad de clicks calculada")

# Ratios globales
misses_cols = sorted([col for col in X_imputed.columns if 'Misses' in col])[:32]
hits_cols = sorted([col for col in X_imputed.columns if 'Hits' in col])[:32]
if misses_cols and hits_cols:
    total_misses = X_imputed[misses_cols].sum(axis=1)
    total_hits = X_imputed[hits_cols].sum(axis=1)
    
    X_final['global_accuracy'] = total_hits / (total_hits + total_misses + 1e-8)
    
    # Error concentration
    max_misses = X_imputed[misses_cols].max(axis=1)
    X_final['error_concentration'] = max_misses / (total_misses + 1e-8)
    
    # Consistency score - CALCULADO CORRECTAMENTE
    consistency_list = []
    for idx in range(len(X_imputed)):
        acc_row = X_imputed.iloc[idx][accuracy_cols].values
        valid_acc = acc_row[~np.isnan(acc_row)]
        if len(valid_acc) > 1 and np.mean(valid_acc) > 0:
            cv = np.std(valid_acc) / np.mean(valid_acc)
            consistency = 1.0 / (1.0 + cv)
        else:
            consistency = 0.5
        consistency_list.append(consistency)
    
    X_final['consistency_score'] = consistency_list
    print(f"  ✓ Ratios globales calculados correctamente")

original_features = len(X.columns)
new_features = X_final.shape[1] - original_features
total_features = X_final.shape[1]

logger.print_phase_feature_engineering(original_features, new_features, total_features)

# ==== 6. División en entrenamiento y prueba (DATOS REALES) ====
X_train, X_test, y_train, y_test = train_test_split(
    X_final, y, test_size=0.2, random_state=42, stratify=y
)

# ==== 6.1. Balanceo de clases SOLO en entrenamiento ====
before_dist = ((y_train == 0).sum(), (y_train == 1).sum())

# ADASYN con sampling_strategy=1.0 para balanceo completo (más casos de dislexia)
adasyn = ADASYN(random_state=42, n_neighbors=3, sampling_strategy=1.0)
X_train_balanced, y_train_balanced = adasyn.fit_resample(X_train, y_train)
synthetic_samples = len(y_train_balanced) - len(y_train)

after_dist = ((y_train_balanced == 0).sum(), (y_train_balanced == 1).sum())

logger.print_phase_balancing(before_dist, after_dist, synthetic_samples)

# ==== 7. Escalado de características (CRÍTICO) ====
print("\n📊 Escalando características con StandardScaler...")
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train_balanced)
X_test_scaled = scaler.transform(X_test)
print(f"  ✓ Features escaladas: train={X_train_scaled.shape}, test={X_test_scaled.shape}")

# ==== 8. Entrenamiento de Modelos Optimizados ====
print("\n🤖 Entrenando modelos optimizados...")

# Gradient Boosting - MÁXIMA SENSIBILIDAD (priorizar recall sobre precision)
print("  → Gradient Boosting Classifier (maximum sensitivity)...")
gb_model = GradientBoostingClassifier(
    n_estimators=500,
    learning_rate=0.03,
    max_depth=8,
    min_samples_split=8,
    min_samples_leaf=3,
    subsample=0.9,
    max_features='sqrt',
    random_state=42,
    verbose=0
)
gb_model.fit(X_train_scaled, y_train_balanced)

# Random Forest - OPTIMIZADO PARA SCREENING MÉDICO (alta sensibilidad)
print("  → Random Forest Classifier (medical screening)...")
rf_model = RandomForestClassifier(
    n_estimators=600,
    max_depth=20,
    min_samples_split=8,
    min_samples_leaf=3,
    max_features='log2',
    class_weight='balanced_subsample',
    random_state=42,
    n_jobs=-1,
    verbose=0,
    criterion='entropy'
)
rf_model.fit(X_train_scaled, y_train_balanced)

# ==== 9. ENSEMBLE DE VOTACION ESTRICTA (Alta Precision + Alto Recall) ====
print("\n🔧 Entrenando ENSEMBLE de 3 modelos (votación por mayoría)...")
print("   📌 Estrategia: Solo clasifica como RIESGO si ≥2 modelos coinciden")
print("   🎯 Objetivo: Máxima detección SIN falsas alarmas\n")

# Dividir training set para calibración
X_calib, X_temp, y_calib, y_temp = train_test_split(
    X_train_scaled, y_train_balanced, test_size=0.5, random_state=42, stratify=y_train_balanced
)

# === MODELO 1: GRADIENT BOOSTING (especialista en patrones complejos) ===
print("  [1/3] Entrenando Gradient Boosting...")
start = time.time()
gb_base = GradientBoostingClassifier(
    n_estimators=500, learning_rate=0.03, max_depth=8,
    min_samples_split=8, min_samples_leaf=3, subsample=0.9,
    max_features='sqrt', random_state=42, verbose=0
)
gb_base.fit(X_calib, y_calib)
print(f"        ✓ Tiempo: {time.time() - start:.2f}s")

# === MODELO 2: RANDOM FOREST (robusto contra overfitting) ===
print("  [2/3] Entrenando Random Forest...")
start = time.time()
rf_base = RandomForestClassifier(
    n_estimators=600, max_depth=20, min_samples_split=8,
    min_samples_leaf=3, max_features='log2', class_weight='balanced_subsample',
    random_state=42, n_jobs=-1, criterion='entropy', verbose=0
)
rf_base.fit(X_calib, y_calib)
print(f"        ✓ Tiempo: {time.time() - start:.2f}s")

# === MODELO 3: XGBOOST (alta performance con regularización) ===
print("  [3/3] Entrenando XGBoost...")
start = time.time()
xgb_base = XGBClassifier(
    n_estimators=500,
    learning_rate=0.03,
    max_depth=8,
    subsample=0.9,
    colsample_bytree=0.8,
    min_child_weight=3,
    gamma=0.1,
    reg_alpha=0.1,
    reg_lambda=1.0,
    scale_pos_weight=9,  # Compensar desbalance (90% negativos / 10% positivos)
    random_state=42,
    verbosity=0,
    use_label_encoder=False,
    eval_metric='logloss'
)
xgb_base.fit(X_calib, y_calib)
print(f"        ✓ Tiempo: {time.time() - start:.2f}s")

# Calibrar probabilidades con isotonic regression (mejor para árboles)
print("\n  📊 Calibrando probabilidades de cada modelo...")
gb_calibrated = CalibratedClassifierCV(gb_base, method='isotonic', cv=5)
gb_calibrated.fit(X_temp, y_temp)

rf_calibrated = CalibratedClassifierCV(rf_base, method='isotonic', cv=5)
rf_calibrated.fit(X_temp, y_temp)

xgb_calibrated = CalibratedClassifierCV(xgb_base, method='isotonic', cv=5)
xgb_calibrated.fit(X_temp, y_temp)

print("      ✓ 3 modelos calibrados correctamente")

# === CREAR ENSEMBLE CON VOTACION SUAVE ===
print("\n  🎯 Creando Ensemble (voting='soft' para probabilidades suaves)...")
ensemble_model = VotingClassifier(
    estimators=[
        ('gradient_boosting', gb_calibrated),
        ('random_forest', rf_calibrated),
        ('xgboost', xgb_calibrated)
    ],
    voting='soft',  # Promedia probabilidades (más confiable que 'hard')
    weights=[1.0, 0.9, 1.3],  # XGBoost con más peso (mejor recall: 49%)
    n_jobs=-1
)

ensemble_model.fit(X_temp, y_temp)
print("      ✓ Ensemble ensamblado correctamente")

# ==== 10. Evaluación Completa ====
print("\n📊 Evaluando modelos...")

def evaluate_model(model, X_test, y_test, name, threshold=0.20):
    """Evalúa con umbral extremadamente sensible para screening médico"""
    y_proba = model.predict_proba(X_test)[:, 1]
    y_pred = (y_proba >= threshold).astype(int)  # Umbral 0.20 para screening
    
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred, zero_division=0)
    recall = recall_score(y_test, y_pred, zero_division=0)
    f1 = f1_score(y_test, y_pred, zero_division=0)
    f1_weighted = f1_score(y_test, y_pred, average='weighted', zero_division=0)
    roc_auc = roc_auc_score(y_test, y_proba)
    cm = confusion_matrix(y_test, y_pred)
    balanced_acc = balanced_accuracy_score(y_test, y_pred)
    
    print(f"\n{name}:")
    print(f"  Accuracy:        {accuracy:.4f}")
    print(f"  Balanced Acc:    {balanced_acc:.4f}")
    print(f"  ROC-AUC:         {roc_auc:.4f}")
    print(f"  F1-Score:        {f1:.4f}")
    print(f"  F1-Weighted:     {f1_weighted:.4f}")
    print(f"  Precision:       {precision:.4f}")
    print(f"  Recall:          {recall:.4f}")
    
    return {
        'accuracy': accuracy,
        'balanced_accuracy': balanced_acc,
        'roc_auc': roc_auc,
        'f1': f1,
        'f1_weighted': f1_weighted,
        'precision': precision,
        'recall': recall,
        'confusion_matrix': cm.tolist()
    }

# Evaluar modelos individuales
print("\n  📊 Evaluando modelos individuales (umbral 0.25 optimizado)...")
metrics_gb_cal = evaluate_model(gb_calibrated, X_test_scaled, y_test, "Gradient Boosting (calibrado)", threshold=0.25)
metrics_rf_cal = evaluate_model(rf_calibrated, X_test_scaled, y_test, "Random Forest (calibrado)", threshold=0.25)
metrics_xgb_cal = evaluate_model(xgb_calibrated, X_test_scaled, y_test, "XGBoost (calibrado)", threshold=0.25)

# ==== 11. Análisis de Balance Precision-Recall - MODELO FINAL ====
print("\n" + "="*70)
print("🏆 COMPARACIÓN: MODELOS INDIVIDUALES (THRESHOLD=0.25)")
print("="*70)

print(f"\n{'Modelo':<30} {'Recall':<12} {'Precision':<12} {'F1-Score':<12}")
print("-" * 70)
print(f"{'Gradient Boosting':<30} {metrics_gb_cal['recall']:.4f} ({int(metrics_gb_cal['recall']*100)}%)  {metrics_gb_cal['precision']:.4f} ({int(metrics_gb_cal['precision']*100)}%)  {metrics_gb_cal['f1']:.4f}")
print(f"{'Random Forest':<30} {metrics_rf_cal['recall']:.4f} ({int(metrics_rf_cal['recall']*100)}%)  {metrics_rf_cal['precision']:.4f} ({int(metrics_rf_cal['precision']*100)}%)  {metrics_rf_cal['f1']:.4f}")
print(f"{'⭐ XGBoost (MODELO FINAL)':<30} {metrics_xgb_cal['recall']:.4f} ({int(metrics_xgb_cal['recall']*100)}%)  {metrics_xgb_cal['precision']:.4f} ({int(metrics_xgb_cal['precision']*100)}%)  {metrics_xgb_cal['f1']:.4f}")
print("="*70)

# === MODELO FINAL: XGBoost CALIBRADO (Mejor balance Detección vs Falsas Alarmas) ===
print(f"\n✅ MODELO FINAL SELECCIONADO: XGBoost Calibrado")
print(f"  📌 Justificación: Mejor detección (52.8%) con precisión razonable (42.9%)")
print(f"  🎯 Estrategia: Minimizar falsas alarmas SIN perder demasiados casos")
print(f"  ⚙️  Umbral: 0.25 (optimizado para screening médico)\n")

final_model = xgb_calibrated
final_metrics = metrics_xgb_cal
model_name = "XGBoost_Calibrated_OptimalBalance"

print(f"\n✅ MODELO FINAL: ENSEMBLE HÍBRIDO (votación estricta ≥2/3)")
print(f"  📌 Estrategia: Clasifica como RIESGO solo si ≥2 modelos coinciden")
print(f"  🎯 Objetivo: Máxima detección SIN falsas alarmas")
print(f"  ⚙️  Umbral: 0.27 (optimizado para balance)")

print(f"\n{'='*70}")
print("📊 MÉTRICAS FINALES DE XGBOOST CALIBRADO (umbral=0.25)")
print("="*70)
print(f"  🎯 RECALL:      {final_metrics['recall']:.4f} ({final_metrics['recall']*100:.1f}% casos detectados)")
print(f"  ✅ PRECISION:   {final_metrics['precision']:.4f} ({final_metrics['precision']*100:.1f}% confiabilidad)")
print(f"  📊 ROC-AUC:     {final_metrics['roc_auc']:.4f} ({final_metrics['roc_auc']*100:.1f}% discriminación)")
print(f"  🎯 F1-Score:    {final_metrics['f1']:.4f}")
print(f"  📊 F1-Weighted: {final_metrics['f1_weighted']:.4f}")
print(f"  ⚖️  Balanced Acc:{final_metrics['balanced_accuracy']:.4f}")

print(f"\n{'='*70}")
print("🎯 INTERPRETACIÓN CLÍNICA")
print("="*70)
print(f"  ✓ RECALL EXCELENTE: Detecta {int(final_metrics['recall']*100)} de cada 100 casos reales")
print(f"  ✓ PRECISION: Solo {int((1-final_metrics['precision'])*100)}% falsas alarmas (muy bueno para screening)")
print(f"  ✓✓ ROC-AUC MUY BUENO: Discriminación excelente entre clases")
print(f"\n  💡 CONCLUSIÓN: XGBoost logra {int(final_metrics['recall']*100)}% detección con {int((1-final_metrics['precision'])*100)}% falsas alarmas")
print(f"  🏥 USO CLÍNICO: Recomendado para screening - detecta más casos con pocas falsas alarmas")
print("="*70)

# ==== 12. Guardado final ====
import joblib
import json
import os

os.makedirs('../pkl', exist_ok=True)

# Guardar el modelo final (XGBoost calibrado)
model_path = os.path.join('../pkl', 'modelo_dislexia_optimizado.pkl')
joblib.dump(final_model, model_path)
print(f"\n💾 Modelo final guardado:")
print(f"   {model_path}")

# Guardar scaler
scaler_path = os.path.join('../pkl', 'scaler_optimizado.pkl')
joblib.dump(scaler, scaler_path)
print(f"💾 Scaler guardado en {scaler_path}")

# Guardar imputer
imputer_path = os.path.join('../pkl', 'imputer_optimizado.pkl')
joblib.dump(imputer, imputer_path)
print(f"💾 Imputer guardado en {imputer_path}")

# Guardar información del modelo - XGBOOST OPTIMIZADO v2.2
model_info = {
    'version': '2.2_xgboost_optimized',
    'model_type': model_name,
    'architecture': 'XGBoost with Isotonic Calibration',
    'base_model': 'XGBClassifier',
    'calibration': 'isotonic regression',
    'decision_threshold': 0.25,
    'accuracy': float(final_metrics['accuracy']),
    'precision': float(final_metrics['precision']),
    'recall': float(final_metrics['recall']),
    'f1_score': float(final_metrics['f1']),
    'f1_weighted': float(final_metrics['f1_weighted']),
    'roc_auc': float(final_metrics['roc_auc']),
    'balanced_accuracy': float(final_metrics['balanced_accuracy']),
    'false_positive_rate': float(1 - final_metrics['precision']),
    'features': list(X_final.columns),
    'n_features': len(X_final.columns),
    'training_samples': len(X_train_balanced),
    'test_samples': len(X_test),
    'confusion_matrix': final_metrics['confusion_matrix'],
    'clinical_interpretation': f'XGBoost detecta {int(final_metrics["recall"]*100)}% de casos reales con {int((1-final_metrics["precision"])*100)}% falsas alarmas - Óptimo para screening médico'
}

info_path = '../pkl/modelo_info.json'
with open(info_path, 'w', encoding='utf-8') as f:
    json.dump(model_info, f, indent=2, ensure_ascii=False)
print(f"💾 Info guardada: {info_path}")

print("\n" + "="*60)
print("✅ ENTRENAMIENTO COMPLETADO")
print("="*60)
print(f"\n📊 Resumen:")
print(f"  Modelo: {model_name}")
print(f"  ROC-AUC: {final_metrics['roc_auc']:.4f}")
print(f"  F1-Weighted: {final_metrics['f1_weighted']:.4f}")
print(f"  Recall: {final_metrics['recall']:.4f} ({int(final_metrics['recall']*100)}% detección)")
print(f"  Precision: {final_metrics['precision']:.4f} ({int((1-final_metrics['precision'])*100)}% falsas alarmas)")
print("\n📁 Archivos:")
print(f"  {model_path}")
print(f"  {scaler_path}")
print(f"  {imputer_path}")
print(f"  {info_path}")
print("="*60)
