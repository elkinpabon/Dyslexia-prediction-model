from flask import jsonify

class Response:
    """Utilidad para respuestas estandarizadas"""
    
    @staticmethod
    def success(data=None, message="Éxito", status_code=200):
        """Respuesta exitosa"""
        return jsonify({
            "success": True,
            "message": message,
            "data": data
        }), status_code
    
    @staticmethod
    def error(message, status_code=400, error_code=None):
        """Respuesta de error"""
        return jsonify({
            "success": False,
            "message": message,
            "error_code": error_code
        }), status_code
    
    @staticmethod
    def validation_error(errors):
        """Error de validación"""
        return jsonify({
            "success": False,
            "message": "Errores de validación",
            "errors": errors
        }), 422

class Validator:
    """Validador de entrada"""
    
    @staticmethod
    def validate_features(features, expected_count=206):
        """Validar características"""
        errors = []
        
        if not isinstance(features, list):
            errors.append("features debe ser una lista")
        elif len(features) != expected_count:
            errors.append(f"Se esperaban {expected_count} características, se recibieron {len(features)}")
        else:
            for i, f in enumerate(features):
                try:
                    float(f)
                except (ValueError, TypeError):
                    errors.append(f"Característica {i} no es numérica: {f}")
        
        return errors if errors else None
