import sys, json, re
from PIL import Image, ImageDraw, ImageFont

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
BOLD_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
FS = 15
font = ImageFont.truetype(FONT_PATH, FS)
bold = ImageFont.truetype(BOLD_PATH, FS)

BG=(13,15,20); FG=(222,226,230); CYAN=(88,196,221); GREEN=(134,196,100)
YELLOW=(224,196,108); GREY=(130,138,148); RED=(224,108,108); BLUE=(100,160,224)
WHITE=(245,245,245)

ansi_re = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]')

def strip_ansi(s):
    return ansi_re.sub('', s)

def color_for(line):
    l = line.strip()
    if l.startswith('WARN'):
        return YELLOW
    if l.startswith('ERRO') or l.startswith('FATA'):
        return RED
    if l.startswith('INFO'):
        return BLUE
    if 'Connection established' in l or 'Route created' in l or 'created' in l.lower() and 'listener' in l.lower():
        return GREEN
    return FG

def render(spec, out_path, width=1360):
    pad=22; line_h=FS+9
    lines = spec['lines']
    height = pad*2 + line_h*len(lines) + 6
    img = Image.new('RGB',(width,height),BG)
    d = ImageDraw.Draw(img)
    y = pad
    for item in lines:
        kind = item.get('type','out')
        text = item.get('text','')
        text = strip_ansi(text)
        if kind == 'kali_prompt':
            seg1 = "┌──(godwin㉿kali)-[~]"
            d.text((pad,y), seg1, font=bold, fill=CYAN)
            y += line_h
            seg2 = "└─$ "
            d.text((pad,y), seg2, font=bold, fill=CYAN)
            d.text((pad+d.textlength(seg2,font=bold), y), text, font=bold, fill=WHITE)
        elif kind == 'root_prompt':
            host = item.get('host','pivot1')
            lbl = f"root@{host}:~# "
            d.text((pad,y), lbl, font=bold, fill=GREEN)
            d.text((pad+d.textlength(lbl,font=bold), y), text, font=bold, fill=WHITE)
        elif kind == 'proxy_prompt':
            lbl = "ligolo-ng » "
            d.text((pad,y), lbl, font=bold, fill=YELLOW)
            d.text((pad+d.textlength(lbl,font=bold), y), text, font=bold, fill=WHITE)
        elif kind == 'agent_prompt':
            host = item.get('host','kali@pivot1')
            lbl = f"[Agent : {host}] » "
            d.text((pad,y), lbl, font=bold, fill=YELLOW)
            d.text((pad+d.textlength(lbl,font=bold), y), text, font=bold, fill=WHITE)
        elif kind == 'blank':
            pass
        else:
            d.text((pad,y), text, font=font, fill=color_for(text))
        y += line_h
    img.save(out_path)

if __name__ == '__main__':
    spec_file = sys.argv[1]
    out_file = sys.argv[2]
    with open(spec_file) as f:
        spec = json.load(f)
    render(spec, out_file)
