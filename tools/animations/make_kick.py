# -*- coding: utf-8 -*-
"""Ön tekme (mae geri) animasyonu: R15 KeyframeSequence (.rbxmx) üretir.

2026-10-18, sahibi 'iki el birbirine birleşsin ve tekme atsın, tekme biçimlerini incele, karakter animasyonu olarak ekle' dedi.
Araştırma (karate mae geri): YÜKLE (diz yukarı, bacak katlı), VUR (bacak düz ileri, kalça öne), GERİ ÇEK (bacak hızla katlanıp iner);
eller tekme boyunca önde ve yukarıda kalır. Sahibinin isteğiyle eller göğsün önünde BİRLEŞİK durur.

Açılar derece; Motor6D.Transform uzayında (R15 eklem çerçeveleri gövdeyle aynı yönde):
X + = öne (kalça/omuz/dirsek), diz - = geriye bükülme, bel + = geriye yaslanma; Y = dikey eksende dönme (omuzlarda + sağ kolu içe çeker).
Kullanım: python tools/animations/make_kick.py  ->  assets/animations/SquatKick.rbxmx
Studio: dosyayı Workspace'e sürükle > KeyframeSequence'e sağ tık > 'Save to Roblox' (Roblox'a kaydet) > çıkan ID'yi Config.Animations.Kick'e yaz.
"""
import math, os

# Eklem (Motor6D) -> Pose adı (Part1) ve ağaçtaki ebeveyn pose
TREE = {
    "LowerTorso": "HumanoidRootPart",
    "UpperTorso": "LowerTorso",
    "Head": "UpperTorso",
    "RightUpperArm": "UpperTorso", "RightLowerArm": "RightUpperArm", "RightHand": "RightLowerArm",
    "LeftUpperArm": "UpperTorso", "LeftLowerArm": "LeftUpperArm", "LeftHand": "LeftLowerArm",
    "RightUpperLeg": "LowerTorso", "RightLowerLeg": "RightUpperLeg", "RightFoot": "RightLowerLeg",
    "LeftUpperLeg": "LowerTorso", "LeftLowerLeg": "LeftUpperLeg", "LeftFoot": "LeftLowerLeg",
}
JOINT_PART = {
    "Waist": "UpperTorso", "Neck": "Head",
    "RightShoulder": "RightUpperArm", "RightElbow": "RightLowerArm", "RightWrist": "RightHand",
    "LeftShoulder": "LeftUpperArm", "LeftElbow": "LeftLowerArm", "LeftWrist": "LeftHand",
    "RightHip": "RightUpperLeg", "RightKnee": "RightLowerLeg", "RightAnkle": "RightFoot",
    "LeftHip": "LeftUpperLeg", "LeftKnee": "LeftLowerLeg", "LeftAnkle": "LeftFoot",
}

# Eller göğsün önünde birleşik (Moves.luau HANDS_TOGETHER ile AYNI değerler)
HANDS = {"RightShoulder": (70, 65), "LeftShoulder": (70, -65), "RightElbow": (40, 0), "LeftElbow": (40, 0)}

def pose(**joints):
    out = {k: (v, 0) for k, v in joints.items()}
    out.update(HANDS)
    return out

# (zaman oranı 0-1, poz) : süre Config.MoveDuration.Kick'e oyunda hızla ölçeklenir; vuruş (ayak duvara) 0.5'te = Config.MoveContact.Kick
LENGTH = 0.8  # animasyonun kendi uzunluğu (sn); oyun hızını ayarlar
KEYS = [
    (0.00, {}),
    (0.22, pose(RightHip=80, RightKnee=-105, RightAnkle=20, LeftHip=6, LeftKnee=-16, Waist=6, Neck=-4)),   # YÜKLE: diz yukarı, eller birleşti
    (0.50, pose(RightHip=95, RightKnee=-2, RightAnkle=35, LeftHip=10, LeftKnee=-14, Waist=14, Neck=-8)),   # VUR: bacak düz, kalça öne, gövde geriye
    (0.66, pose(RightHip=92, RightKnee=-4, RightAnkle=35, LeftHip=10, LeftKnee=-14, Waist=13, Neck=-8)),   # kısa tutuş
    (0.84, pose(RightHip=60, RightKnee=-95, RightAnkle=15, LeftHip=5, LeftKnee=-14, Waist=5, Neck=-3)),    # GERİ ÇEK: bacak katlanır
    (1.00, {}),
]

def matrix(x_deg, y_deg):
    a, b = math.radians(x_deg), math.radians(y_deg)
    rx = [[1, 0, 0], [0, math.cos(a), -math.sin(a)], [0, math.sin(a), math.cos(a)]]
    ry = [[math.cos(b), 0, math.sin(b)], [0, 1, 0], [-math.sin(b), 0, math.cos(b)]]
    return [[sum(ry[i][k] * rx[k][j] for k in range(3)) for j in range(3)] for i in range(3)]

def cframe_xml(x_deg=0, y_deg=0):
    m = matrix(x_deg, y_deg)
    cells = "".join(f"<R{i}{j}>{m[i][j]:.6f}</R{i}{j}>" for i in range(3) for j in range(3))
    return f'<CoordinateFrame name="CFrame"><X>0</X><Y>0</Y><Z>0</Z>{cells}</CoordinateFrame>'

ref = [0]
def nref():
    ref[0] += 1
    return f"RBX{ref[0]:04d}"

def pose_xml(part, angles):
    x, y = (0, 0)
    for joint, p in JOINT_PART.items():
        if p == part and joint in angles:
            x, y = angles[joint]
    children = "".join(pose_xml(c, angles) for c, parent in TREE.items() if parent == part)
    return (f'<Item class="Pose" referent="{nref()}"><Properties>{cframe_xml(x, y)}'
            f'<token name="EasingDirection">2</token><token name="EasingStyle">3</token>'
            f'<string name="Name">{part}</string><float name="Weight">1</float></Properties>{children}</Item>')

def build():
    frames = ""
    for ratio, angles in KEYS:
        frames += (f'<Item class="Keyframe" referent="{nref()}"><Properties><string name="Name">Keyframe</string>'
                   f'<float name="Time">{ratio * LENGTH:.4f}</float></Properties>{pose_xml("HumanoidRootPart", angles)}</Item>')
    return ('<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4">'
            f'<Item class="KeyframeSequence" referent="{nref()}"><Properties><bool name="Loop">false</bool>'
            '<token name="Priority">2</token><string name="Name">SquatKick</string></Properties>'
            f'{frames}</Item></roblox>')

if __name__ == "__main__":
    out = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "animations", "SquatKick.rbxmx")
    with open(out, "w", encoding="utf-8") as f:
        f.write(build())
    print("yazildi:", os.path.normpath(out))
