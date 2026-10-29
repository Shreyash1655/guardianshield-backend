import re
from urllib.parse import urlparse

class URLIntelligence:
    SUSPICIOUS_TLDS = ['.xyz', '.top', '.loan', '.click', '.gq', '.ml', '.work', '.zip']
    SUSPICIOUS_KEYWORDS = ['login', 'verify', 'secure', 'account', 'update', 'banking', 'support', 'signin', 'auth', 'wallet']

    @staticmethod
    def extract_urls(text):
        if not text:
            return []
        url_pattern = r'https?://[^\s<>"]+|www\.[^\s<>"]+'
        return re.findall(url_pattern, text)

    @classmethod
    def analyze_url(cls, url):
        if not url.startswith("http://") and not url.startswith("https://"):
            if url.startswith("www."):
                url = "http://" + url
            else:
                return {"url": url, "risk": "INVALID", "indicators": ["Unsafe or unrecognized URL scheme"]}

        parsed = urlparse(url)
        domain = parsed.netloc.lower()
        path = parsed.path.lower()
        query = parsed.query.lower()

        indicators = []
        risk_score = 0.0

        ip_pattern = r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'
        if re.match(ip_pattern, domain.split(':')[0]):
            indicators.append("IP address used instead of domain name")
            risk_score += 0.4

        if any(domain.endswith(tld) for tld in cls.SUSPICIOUS_TLDS):
            indicators.append("Suspicious top-level domain (TLD)")
            risk_score += 0.3

        full_url_str = domain + path + query
        matched_keywords = [kw for kw in cls.SUSPICIOUS_KEYWORDS if kw in full_url_str]
        if matched_keywords:
            indicators.append(f"Suspicious keywords detected: {', '.join(matched_keywords)}")
            risk_score += 0.3

        private_hosts = ['localhost', '127.0.0.1', '10.', '192.168.', '172.16.']
        if any(ph in domain for ph in private_hosts):
            indicators.append("Potential SSRF / Private network target detected")
            risk_score += 0.5

        risk_score = min(risk_score, 1.0)
        risk_level = "SAFE"
        if risk_score >= 0.6:
            risk_level = "HIGH_RISK"
        elif risk_score >= 0.3:
            risk_level = "SUSPICIOUS"

        return {
            "url": url,
            "domain": domain,
            "risk_score": risk_score,
            "risk_level": risk_level,
            "indicators": indicators
        }