"""Tek bir petin YAKIN önizlemesi (3/4 açı): blender -b -P tools/blender/pet_closeup.py -- yeti
Çıktı: assets/blender/previews/pet_<id>_closeup.png (pets.py / pets_more.py / pets_space.py çizicilerini kullanır)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import common as c  # noqa: E402
import pets as P  # noqa: E402
import pets_more as PM  # noqa: E402
import pets_space as PS  # noqa: E402
from lib import Model  # noqa: E402

pet_id = c.argv_after_dashes()[0]
builders = {pid: (fn, col) for pid, fn, col in P.PETS + PM.PETS + PS.PETS}
fn, col = builders[pet_id]
c.reset()
c.setup_render(resolution=900, samples=40)
model = Model("pet_" + pet_id)
fn(model, col)
obj = model.finish(os.path.join(c.OUT, "textures"))
c.add_floor((205, 214, 240), size=40)
c.add_lights(center=(0, 0, 1.2), distance=10)
c.render_view(os.path.join(c.OUT, "previews", f"pet_{pet_id}_closeup.png"), center=(0, 0, 1.25), distance=7.5, azimuth_deg=22, elevation_deg=14, lens=50)
