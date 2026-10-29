import hashlib
from app.models.incident import Incident

class ScamDNAEngine:
    @staticmethod
    def compute_cluster_id(content):
        hasher = hashlib.sha256()
        hasher.update(content.encode('utf-8', errors='ignore'))
        return f"DNA-{hasher.hexdigest()[:12]}"

    @staticmethod
    def find_correlations(incident):
        similar = Incident.query.filter(
            Incident.dna_cluster_id == incident.dna_cluster_id,
            Incident.id != incident.id
        ).all()
        
        return [
            {
                "related_incident_id": inc.id,
                "channel": inc.channel,
                "created_at": inc.created_at.isoformat(),
                "reason": "Shared scam pattern and identical DNA cluster signature."
            } for inc in similar
        ] 