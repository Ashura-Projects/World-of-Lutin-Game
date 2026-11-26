"""Outils Blender communs aux scripts de style (primitives, matériaux, rendu).

Convention : Z vers le haut, 1 unité = 1 bloc. Les personnages regardent vers -Y.
"""

import math

import bpy
from mathutils import Euler, Vector

_MATS: dict = {}


def reset_scene() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _MATS.clear()
    sc = bpy.context.scene
    sc.render.engine = "CYCLES"
    sc.cycles.device = "CPU"
    sc.cycles.samples = 48
    sc.cycles.use_denoising = True
    sc.cycles.max_bounces = 4
    sc.render.film_transparent = False
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"


def srgb(c):
    """Couleur 0-255 sRGB -> linéaire 0-1 (Blender travaille en linéaire)."""
    def f(v):
        v = v / 255.0
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4
    return (f(c[0]), f(c[1]), f(c[2]), 1.0)


def mat(name, color, rough=0.65, emit=0.0, metal=0.0):
    key = (name, tuple(color), rough, emit, metal)
    if key in _MATS:
        return _MATS[key]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = srgb(color)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit > 0:
        b.inputs["Emission Color"].default_value = srgb(color)
        b.inputs["Emission Strength"].default_value = emit
    _MATS[key] = m
    return m


def _finish(ob, material, smooth=False):
    if material is not None:
        ob.data.materials.append(material)
    for p in ob.data.polygons:
        p.use_smooth = smooth
    return ob


def sphere(loc, scale, material, seg=12, rings=8, rot=(0, 0, 0), smooth=False):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1, location=loc)
    ob = bpy.context.object
    ob.scale = scale if isinstance(scale, (tuple, list)) else (scale, scale, scale)
    ob.rotation_euler = Euler(rot)
    return _finish(ob, material, smooth)


def cyl(loc, r, depth, material, verts=8, rot=(0, 0, 0), r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc)
    ob = bpy.context.object
    ob.rotation_euler = Euler(rot)
    return _finish(ob, material)


def cone(loc, r, depth, material, verts=10, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=0, depth=depth, location=loc)
    ob = bpy.context.object
    ob.rotation_euler = Euler(rot)
    return _finish(ob, material)


def limb(a, b, r, material, verts=8):
    """Cylindre allant du point a au point b (bras, jambes)."""
    va, vb = Vector(a), Vector(b)
    d = vb - va
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=d.length, location=(va + vb) / 2)
    ob = bpy.context.object
    ob.rotation_euler = d.to_track_quat("Z", "Y").to_euler()
    return _finish(ob, material)


def box(loc, size, material, rot=(0, 0, 0), bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    ob = bpy.context.object
    ob.scale = size
    ob.rotation_euler = Euler(rot)
    if bevel > 0:
        bpy.ops.object.transform_apply(scale=True)
        mod = ob.modifiers.new("bev", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    return _finish(ob, material)


def torus(loc, r_major, r_minor, material, rot=(0, 0, 0), seg=16):
    bpy.ops.mesh.primitive_torus_add(major_radius=r_major, minor_radius=r_minor, major_segments=seg,
                                     minor_segments=6, location=loc)
    ob = bpy.context.object
    ob.rotation_euler = Euler(rot)
    return _finish(ob, material)


def group(objs, name, loc=(0, 0, 0), rot_z=0.0, scale=1.0):
    """Range des objets sous un parent vide (pour tourner / déplacer un personnage entier)."""
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    for o in objs:
        o.parent = root
    root.location = loc
    root.rotation_euler = (0, 0, rot_z)
    root.scale = (scale, scale, scale)
    return root


def camera(loc, target, lens=50, ortho=None):
    cam_data = bpy.data.cameras.new("cam")
    if ortho:
        cam_data.type = "ORTHO"
        cam_data.ortho_scale = ortho
    cam_data.lens = lens
    cam = bpy.data.objects.new("cam", cam_data)
    bpy.context.scene.collection.objects.link(cam)
    cam.location = loc
    d = Vector(target) - Vector(loc)
    cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
    bpy.context.scene.camera = cam
    return cam


def lights(sun_dir=(0.9, -0.6, 0.0), strength=3.0, world=(200, 214, 235), world_strength=0.9,
           sun_color=(255, 244, 225)):
    sd = bpy.data.lights.new("sun", "SUN")
    sd.energy = strength
    sd.color = srgb(sun_color)[:3]
    sd.angle = math.radians(8)
    sun = bpy.data.objects.new("sun", sd)
    sun.rotation_euler = Euler(sun_dir)
    bpy.context.scene.collection.objects.link(sun)
    w = bpy.data.worlds.new("world")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = srgb(world)
    bg.inputs["Strength"].default_value = world_strength
    bpy.context.scene.world = w


def backdrop(color=(236, 230, 216), z=0.0):
    """Sol courbe (studio) pour les planches de personnages."""
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 0, z))
    ob = bpy.context.object
    m = mat("backdrop", color, 0.9)
    ob.data.materials.append(m)
    bpy.ops.mesh.primitive_plane_add(size=40, location=(0, 12, 0), rotation=(math.pi / 2, 0, 0))
    bpy.context.object.data.materials.append(m)
    return ob


def render(path, w, h, samples=None):
    sc = bpy.context.scene
    sc.render.resolution_x = w
    sc.render.resolution_y = h
    sc.render.resolution_percentage = 100
    if samples:
        sc.cycles.samples = samples
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def clear_objects() -> None:
    for o in list(bpy.data.objects):
        if o.type not in ("CAMERA", "LIGHT"):
            bpy.data.objects.remove(o, do_unlink=True)
