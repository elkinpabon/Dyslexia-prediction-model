# -*- coding: utf-8 -*-
# ==============================================
#  REENTRENAMIENTO DEL MODELO - CALIBRADO PARA LA APP
#  Optimizado para los datos de tu aplicación (48 rondas)
#  Objetivo: Predicciones lógicas y realistas
# ==============================================

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    accuracy_score, classification_report, confusion_matrix, 
    roc_auc_score, f1_score, precision_score, recall_score, balanced_accuracy_score
)
from sklearn.impute import SimpleImputer
from sklearn.calibration import CalibratedClassifierCV
from xgboost import XGBClassifier
import joblib
import json
import os
from log_info import logger, initialize_logger

initialize_logger()
logger.print_header("REENTRENAMIENTO DEL MODELO - CALIBRADO PARA LA APP")

# ==== CARGAR DATOS ====
logger.print_section("CARGA DE DATOS")
desktop_df = pd.read_csv("../dataset/Dyt-desktop.csv", sep=';')
tablet_df = pd.read_csv("../dataset/Dyt-tablet.csv", sep=';')
combined_df = pd.concat([desktop_df, tablet_df], ignore_index=True)
logger.print_phase_data_loading(len(desktop_df), len(tablet_df), len(combined_df))

# ==== PREPROCESAMIENTO ====
logger.print_section("PREPROCESAMIENTO Y LIMPIEZA")

# Convertir columnas numéricas
for col in combined_df.columns:
    if col not in ["Gender", "Nativelang", "Otherlang", "Dyslexia"]:
        combined_df[col] = pd.to_numeric(combined_df[col], errors="coerce")

# Eliminar filas sin etiqueta
combined_df = combined_df.dropna(subset=["Dyslexia"])

# Codificar categorías
combined_df["Gender"] = combined_df["Gender"].map({"Male": 1, "Female": 0})
combined_df["Nativelang"] = combined_df["Nativelang"].map({"Yes": 1, "No": 0})
combined_df["Otherlang"] = combined_df["Otherlang"].map({"Yes": 1, "No": 0})
combined_df["Dyslexia"] = combined_df["Dyslexia"].map({"Yes": 1, "No": 0})

X = combined_df.drop(columns=["Dyslexia"])
y = combined_df["Dyslexia"]

logger.print_phase_preprocessing(len(combined_df), len(X.columns), 3)
logger.print_success(f"Distribución: Sin dislexia: {(y==0).sum()} | Con dislexia: {(y==1).sum()}")

# ==== IMPUTACIÓN ====
logger.print_section("IMPUTACIÓN DE VALORES FALTANTES")
imputer = SimpleImputer(strategy="median")
X_imputed = pd.DataFrame(imputer.fit_transform(X), columns=X.columns)
logger.print_phase_imputation(X.isnull().sum().sum(), X_imputed.isnull().sum().sum())

# ==== FEATURE ENGINEERING TEMPORAL ====
logger.print_section("FEATURE ENGINEERING TEMPORAL")
X_final = X_imputed.copy()

# Tendencias de accuracy
accuracy_cols = sorted([col for col in X_imputed.columns if 'Accuracy' in col])[:32]
if accuracy_cols:
    accuracy_trend = []
    accuracy_first = []
    accuracy_second = []
    accuracy_improve = []
    
    for idx in range(len(X_imputed)):
        values = X_imputed.iloc[idx][accuracy_cols].values
        
        if len(values) > 1 and np.sum(~np.isnan(values)) > 1:
            valid_mask = ~np.isnan(values)
            valid_idx = np.where(valid_mask)[0]
            valid_vals = values[valid_mask]
            if len(valid_vals) > 1:
                coeffs = np.polyfit(valid_idx, valid_vals, 1)
                trend = float(coeffs[0])
            else:
                trend = 0.0
        else:
            trend = 0.0
        
        accuracy_trend.append(trend)
        
        first_half = np.nanmean(values[:16]) if len(values) > 0 else 0.0
        second_half = np.nanmean(values[16:32]) if len(values) > 16 else 0.0
        
        accuracy_first.append(first_half)
        accuracy_second.append(second_half)
        accuracy_improve.append(second_half - first_half)
    
    X_final['accuracy_trend'] = accuracy_trend
    X_final['accuracy_mean_first_half'] = accuracy_first
    X_final['accuracy_mean_second_half'] = accuracy_second
    X_final['accuracy_improvement'] = accuracy_improve
    logger.print_success("Tendencias de accuracy calculadas")

# Variabilidad de clicks
clicks_cols = sorted([col for col in X_imputed.columns if 'Clicks' in col])[:32]
if clicks_cols:
    X_final['clicks_variability'] = X_imputed[clicks_cols].std(axis=1)
    X_final['clicks_total'] = X_imputed[clicks_cols].sum(axis=1)
    logger.print_success("Variabilidad de clicks calculada")

# Ratios globales
misses_cols = sorted([col for col in X_imputed.columns if 'Misses' in col])[:32]
hits_cols = sorted([col for col in X_imputed.columns if 'Hits' in col])[:32]
if misses_cols and hits_cols:
    total_misses = X_imputed[misses_cols].sum(axis=1)
    total_hits = X_imputed[hits_cols].sum(axis=1)
    
    X_final['global_accuracy'] = total_hits / (total_hits + total_misses + 1e-8)
    max_misses = X_imputed[misses_cols].max(axis=1)
    X_final['error_concentration'] = max_misses / (total_misses + 1e-8)
    
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
    logger.print_success("Ratios globales calculados")

logger.print_success(f"Total features: {X_final.shape[1]}")

# ==== DIVISIÓN TRAIN/TEST ====
logger.print_section("DIVISIÓN TRAIN/TEST")
X_train, X_test, y_train, y_test = train_test_split(
    X_final, y, test_size=0.2, random_state=42, stratify=y
)
logger.print_phase_training(len(X_train), len(X_test), 5, {'n_estimators': 400, 'max_depth': 6})

# ==== ESCALADO ====
logger.print_section("ESCALADO DE FEATURES")
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)
logger.print_success("Features escaladas correctamente")

# ==== ENTRENAMIENTO: XGBoost OPTIMIZADO PARA TU APP ====
logger.print_section("ENTRENAMIENTO DEL MODELO")
logger.print_info("Configuración: scale_pos_weight=8.5, max_depth=6, learning_rate=0.05")

model = XGBClassifier(
    n_estimators=400,
    learning_rate=0.05,
    max_depth=6,
    min_child_weight=4,
    subsample=0.85,
    colsample_bytree=0.8,
    gamma=0.2,
    reg_alpha=0.05,
    reg_lambda=1.0,
    scale_pos_weight=8.5,
    random_state=42,
    verbosity=0,
    use_label_encoder=False,
    eval_metric='logloss'
)

model.fit(X_train_scaled, y_train)
logger.print_success("Modelo entrenado")

# ==== CALIBRACIÓN ====
logger.print_section("CALIBRACIÓN DE PROBABILIDADES")
model_calibrated = CalibratedClassifierCV(model, method='isotonic', cv=5)
model_calibrated.fit(X_train_scaled, y_train)
logger.print_success("Modelo calibrado con Isotonic Regression")

# ==== EVALUACIÓN ====
logger.print_section("EVALUACIÓN DEL MODELO")

y_proba = model_calibrated.predict_proba(X_test_scaled)[:, 1]
y_pred = (y_proba >= 0.40).astype(int)

accuracy = accuracy_score(y_test, y_pred)
precision = precision_score(y_test, y_pred, zero_division=0)
recall = recall_score(y_test, y_pred, zero_division=0)
f1 = f1_score(y_test, y_pred, zero_division=0)
roc_auc = roc_auc_score(y_test, y_proba)
balanced_acc = balanced_accuracy_score(y_test, y_pred)
cm = confusion_matrix(y_test, y_pred)

metrics = {
    'accuracy_test': accuracy,
    'precision': precision,
    'recall': recall,
    'f1': f1,
    'roc_auc': roc_auc,
    'balanced_acc': balanced_acc
}

logger.print_summary({
    'Accuracy': accuracy,
    'Precision': precision,
    'Recall': recall,
    'F1-Score': f1,
    'ROC-AUC': roc_auc,
    'Balanced Accuracy': balanced_acc
})

logger.print_info(f"Matriz de confusión: TN={cm[0][0]} | FP={cm[0][1]} | FN={cm[1][0]} | TP={cm[1][1]}")

# ==== GUARDAR MODELO ====
logger.print_section("GUARDANDO ARCHIVOS DEL MODELO")

os.makedirs('../pkl', exist_ok=True)

# Guardar modelo
model_path = '../pkl/modelo_dislexia.pkl'
joblib.dump(model_calibrated, model_path)

# Guardar scaler
scaler_path = '../pkl/scaler.pkl'
joblib.dump(scaler, scaler_path)

# Guardar imputer
imputer_path = '../pkl/imputer.pkl'
joblib.dump(imputer, imputer_path)

# Guardar información
model_info = {
    'version': '3.0_app_calibrated',
    'model_type': 'XGBoost_Isotonic_Calibrated',
    'description': 'Modelo reentrenado y calibrado específicamente para tu aplicación de screening de dislexia',
    'decision_threshold': 0.40,
    'accuracy': float(accuracy),
    'precision': float(precision),
    'recall': float(recall),
    'f1_score': float(f1),
    'roc_auc': float(roc_auc),
    'balanced_accuracy': float(balanced_acc),
    'false_positive_rate': float(1 - precision),
    'features': list(X_final.columns),
    'n_features': len(X_final.columns),
    'training_samples': len(X_train),
    'test_samples': len(X_test),
    'confusion_matrix': {
        'true_negatives': int(cm[0][0]),
        'false_positives': int(cm[0][1]),
        'false_negatives': int(cm[1][0]),
        'true_positives': int(cm[1][1])
    },
    'interpretation': f'Detecta {int(recall*100)}% de casos con {int((1-precision)*100)}% falsas alarmas. Óptimo para screening.'
}

info_path = '../pkl/modelo_info.json'
with open(info_path, 'w', encoding='utf-8') as f:
    json.dump(model_info, f, indent=2, ensure_ascii=False)

files_created = ['modelo_dislexia.pkl', 'scaler.pkl', 'imputer.pkl', 'modelo_info.json']
logger.print_phase_serialization(files_created, '../pkl')

logger.print_header("REENTRENAMIENTO COMPLETADO")
logger.print_model_ready()
logger.print_info("Cambios se aplicarán en el próximo APK compilado")

print("\n" + "="*80 + "\n")
