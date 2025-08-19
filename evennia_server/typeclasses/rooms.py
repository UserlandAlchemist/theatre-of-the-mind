"""
Room

Rooms are simple containers that has no location of their own.

"""
from evennia.contrib.grid.extended_room import ExtendedRoom
from evennia.contrib.rpg.rpsystem import ContribRPRoom

from .objects import ObjectParent


class Room(ObjectParent, ContribRPRoom, ExtendedRoom):
    """
    Rooms are like any Object, except their location is None
    (which is default). They also use basetype_setup() to
    add locks so they cannot be puppeted or picked up.
    (to change that, use at_object_creation instead)

    See mygame/typeclasses/objects.py for a list of
    properties and methods available on all Objects.
    """

    pass
