from flask import Flask
from app.config import Config
from app.models import db
from app.routes.health_routes import health_bp
from app.routes.auth_routes import auth_bp
from app.routes.analyze_routes import analyze_bp
from app.routes.incident_routes import incident_bp
from app.routes.caretaker_routes import caretaker_bp
from app.routes.alert_routes import alert_bp
from app.routes.dashboard_routes import dashboard_bp

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    db.init_app(app)

    with app.app_context():
        db.create_all()

    app.register_blueprint(health_bp, url_prefix='/api/v1')
    app.register_blueprint(auth_bp, url_prefix='/api/v1/auth')
    app.register_blueprint(analyze_bp, url_prefix='/api/v1')
    app.register_blueprint(incident_bp, url_prefix='/api/v1')
    app.register_blueprint(caretaker_bp, url_prefix='/api/v1')
    app.register_blueprint(alert_bp, url_prefix='/api/v1')
    app.register_blueprint(dashboard_bp, url_prefix='/api/v1')

    return app