# ==============================================
#  MODELO DE DETECCION DE DISLEXIA
#  Dataset: Predicting Risk of Dyslexia (PLOS ONE / Kaggle)
#  Autor: Elkin Pabon
# ==============================================

# ==== 1. Importacion de librerias ====
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score, StratifiedKFold
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, roc_auc_score, roc_curve,
    precision_recall_curve, f1_score, balanced_accuracy_score
)
from sklearn.impute import SimpleImputer
from imblearn.over_sampling import ADASYN, BorderlineSMOTE
import matplotlib.pyplot as plt
import seaborn as sns
import joblib
import json
import time

from log_info import logger, initialize_logger

# ==== 2. Carga y union de datasets ====
desktop_df = pd.read_csv("Dyt-desktop.csv", sep=';')
tablet_df = pd.read_csv("Dyt-tablet.csv", sep=';')
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

# ==== 5.1. Feature Engineering Temporal ====
# Tendencias temporales (mejora/empeoramiento a lo largo de juegos)
accuracy_cols = [col for col in X_imputed.columns if 'Accuracy' in col and col != 'Accuracy']
if accuracy_cols:
    accuracy_values = X_imputed[accuracy_cols[:10]].values  # Primeros 10 juegos
    X_imputed['accuracy_trend'] = np.polyfit(range(len(accuracy_cols[:10])), accuracy_values.T, 1)[0]
    X_imputed['accuracy_mean_first_half'] = accuracy_values[:, :5].mean(axis=1)
    X_imputed['accuracy_mean_second_half'] = accuracy_values[:, 5:].mean(axis=1)
    X_imputed['accuracy_improvement'] = X_imputed['accuracy_mean_second_half'] - X_imputed['accuracy_mean_first_half']

# Variabilidad en el rendimiento
clicks_cols = [col for col in X_imputed.columns if 'Clicks' in col and col != 'Clicks'][:10]
if clicks_cols:
    X_imputed['clicks_variability'] = X_imputed[clicks_cols].std(axis=1)
    X_imputed['clicks_total'] = X_imputed[clicks_cols].sum(axis=1)

# Ratios de rendimiento
misses_cols = [col for col in X_imputed.columns if 'Misses' in col and col != 'Misses'][:10]
hits_cols = [col for col in X_imputed.columns if 'Hits' in col and col != 'Hits'][:10]
if misses_cols and hits_cols:
    total_misses = X_imputed[misses_cols].sum(axis=1)
    total_hits = X_imputed[hits_cols].sum(axis=1)
    X_imputed['global_accuracy'] = total_hits / (total_hits + total_misses + 1e-8)
    X_imputed['error_concentration'] = X_imputed[misses_cols].max(axis=1) / (total_misses + 1e-8)

# Agregar más características derivadas
try:
    reaction_cols = [col for col in X_imputed.columns if 'ReactionTime' in col][:10]
    if reaction_cols:
        X_imputed['trajectory_velocity'] = X_imputed[reaction_cols].mean(axis=1)
        X_imputed['acceleration_avg'] = X_imputed[reaction_cols].diff(axis=1).mean(axis=1)
except:
    pass

try:
    pause_cols = [col for col in X_imputed.columns if 'Pause' in col or 'Duration' in col][:5]
    if pause_cols:
        X_imputed['pause_duration_pattern'] = X_imputed[pause_cols].std(axis=1)
except:
    pass

try:
    X_imputed['initial_response_time'] = X_imputed.iloc[:, 0] if len(X_imputed.columns) > 0 else 0
    X_imputed['consistency_score'] = X_imputed.std(axis=1)
except:
    pass

original_features = len(X.columns)
new_features = X_imputed.shape[1] - original_features
total_features = X_imputed.shape[1]

logger.print_phase_feature_engineering(original_features, new_features, total_features)

# ==== 6. División en entrenamiento y prueba (DATOS REALES) ====
X_train, X_test, y_train, y_test = train_test_split(
    X_imputed, y, test_size=0.2, random_state=42, stratify=y
)

# ==== 6.1. Balanceo de clases SOLO en entrenamiento ====
before_dist = ((y_train == 0).sum(), (y_train == 1).sum())

try:
    adasyn = ADASYN(random_state=42, n_neighbors=3)
    X_train_balanced, y_train_balanced = adasyn.fit_resample(X_train, y_train)
    synthetic_samples = len(y_train_balanced) - len(y_train)
except:
    borderline_smote = BorderlineSMOTE(random_state=42, k_neighbors=3)
    X_train_balanced, y_train_balanced = borderline_smote.fit_resample(X_train, y_train)
    synthetic_samples = len(y_train_balanced) - len(y_train)

after_dist = ((y_train_balanced == 0).sum(), (y_train_balanced == 1).sum())

logger.print_phase_balancing(before_dist, after_dist, synthetic_samples)

# ==== 8. Entrenamiento del modelo ====
hyperparameters = {
    'n_estimators': 500,
    'max_depth': 20,
    'min_samples_split': 5,
    'min_samples_leaf': 2,
    'max_features': 'sqrt',
    'class_weight': 'balanced_subsample',
    'random_state': 42
}

logger.print_phase_training(len(X_train_balanced), len(X_test), 10, hyperparameters)

rf = RandomForestClassifier(
    n_estimators=500,
    max_depth=20,
    min_samples_split=5,
    min_samples_leaf=2,
    max_features='sqrt',
    class_weight="balanced_subsample",
    random_state=42,
    n_jobs=-1,
    verbose=0
)

rf.fit(X_train_balanced, y_train_balanced)

# ==== 9. Evaluación ====
y_pred = rf.predict(X_test)
y_prob = rf.predict_proba(X_test)[:, 1]

# Validación cruzada estratificada (K=10 para máxima robustez)
cv_scores = cross_val_score(rf, X_train_balanced, y_train_balanced, cv=StratifiedKFold(n_splits=10, shuffle=True, random_state=42), scoring='roc_auc')

acc = accuracy_score(y_test, y_pred)
roc_auc = roc_auc_score(y_test, y_prob)
report = classification_report(y_test, y_pred)
cm = confusion_matrix(y_test, y_pred)

# Metricas adicionales para datos medicos desbalanceados
f1 = f1_score(y_test, y_pred)
balanced_acc = balanced_accuracy_score(y_test, y_pred)
precision, recall, _ = precision_recall_curve(y_test, y_prob)
pr_auc = np.trapz(recall, precision)

# Calcular elementos de matriz de confusion para mostrar
tn, fp, fn, tp = cm.ravel()
specificity = tn / (tn + fp)
sensitivity = tp / (tp + fn)

# Construir diccionario de métricas
metrics = {
    'accuracy_train': accuracy_score(y_train, rf.predict(X_train)),
    'accuracy_test': acc,
    'balanced_accuracy_train': balanced_accuracy_score(y_train, rf.predict(X_train)),
    'balanced_accuracy_test': balanced_acc,
    'f1_train': f1_score(y_train, rf.predict(X_train)),
    'f1_test': f1,
    'roc_auc_train': roc_auc_score(y_train, rf.predict_proba(X_train)[:, 1]),
    'roc_auc_test': roc_auc,
    'pr_auc_train': pr_auc,
    'pr_auc_test': pr_auc,
    'precision_train': precision_recall_curve(y_train, rf.predict_proba(X_train)[:, 1])[0].mean(),
    'precision_test': precision_recall_curve(y_test, y_prob)[0].mean(),
}

logger.print_phase_evaluation(metrics, cv_scores)

# Obtener feature importances para serialización
importances = pd.Series(rf.feature_importances_, index=X_imputed.columns)
top_features = importances.sort_values(ascending=False).head(10)

# ==== 10. Guardado final ====

# ==== 10. Guardado final ====
import joblib
import json
import os

# Crear carpeta pkl si no existe
os.makedirs('pkl', exist_ok=True)

# Guardar modelo optimizado
model_path = os.path.join('pkl', 'modelo_dislexia_optimizado.pkl')
joblib.dump(rf, model_path)

# Guardar preprocesadores
imputer_path = os.path.join('pkl', 'imputer_optimizado.pkl')
joblib.dump(imputer, imputer_path)

# Guardar informacion del modelo
model_info = {
    'version': '2.0_fast_optimized',
    'accuracy': float(acc),
    'roc_auc': float(roc_auc), 
    'f1_score': float(f1),
    'balanced_accuracy': float(balanced_acc),
    'cv_roc_auc_mean': float(cv_scores.mean()),
    'cv_roc_auc_std': float(cv_scores.std()),
    'features': list(X_imputed.columns),
    'n_features': len(X_imputed.columns),
    'training_samples': len(X_train_balanced),
    'test_samples_real': len(X_test),
    'feature_importance_top10': dict(zip(top_features.index[:10], [float(v) for v in top_features.values[:10]]))
}

info_path = os.path.join('pkl', 'modelo_info.json')
with open(info_path, 'w') as f:
    json.dump(model_info, f, indent=2)

# Llamar al logger para serialización
files_created = ['modelo_dislexia_optimizado.pkl', 'imputer_optimizado.pkl', 'modelo_info.json']
logger.print_phase_serialization(files_created, 'pkl')

logger.print_model_ready()
