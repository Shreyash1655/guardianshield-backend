import re

TYPES = {
    "Bank/KYC": r"kyc|bank|account|blocked|pan card|aadhaar",
    "OTP": r"\botp\b|\bpin\b|cvv|verification code",
    "Lottery/Prize": r"lottery|you won|prize|reward|lucky",
    "Job": r"job offer|work from home|part.?time|earn \d+",
    "Delivery": r"parcel|courier|delivery|customs",
    "Investment": r"invest|crypto|profit|trading|returns",
    "Impersonation": r"police|cbi|arrest|customs officer|income tax|relative|accident",
}

def scam_type(text):
    return next((k for k, r in TYPES.items() if re.search(r, text, re.I)), "Other")

def channel(text, default="sms"):
    t = text.lower()
    if "subject:" in t or re.search(r"\S+@\S+\.\S+", t):
        return "email"
    if "whatsapp" in t:
        return "whatsapp"
    return default