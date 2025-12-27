# Python API for controlling the programmable agent
# Uses py4godot to expose agent functionality to user code

from godot import exposed, export
from godot.classdb import Node


@exposed
class AgentAPI(Node):
    """
    Python API for controlling the programmable agent.
    This class is exposed to user Python code as the 'agent' global variable.
    """

    def _ready(self):
        # Get references to agent components
        parent = self.get_parent()
        self._controller = parent.get_node("AgentController")
        self._interaction = parent.get_node("AgentInteraction")

    # Movement API
    def move(self, direction: str, distance: float = 1.0):
        """
        Move agent in a direction.
        direction: "forward", "back", "left", "right", "up", "down"
        distance: number of blocks (default 1.0)
        """
        if not self._controller:
            return

        direction = direction.lower()
        if direction == "forward":
            self._controller.move_forward(distance)
        elif direction == "back" or direction == "backward":
            self._controller.move_forward(-distance)
        elif direction == "left":
            # Turn left, move forward, turn back right
            self._controller.turn_left(90)
            self._controller.move_forward(distance)
            self._controller.turn_right(90)
        elif direction == "right":
            # Turn right, move forward, turn back left
            self._controller.turn_right(90)
            self._controller.move_forward(distance)
            self._controller.turn_left(90)
        elif direction == "up":
            self._controller.move_up(distance)
        elif direction == "down":
            self._controller.move_down(distance)
        else:
            print(f"Unknown direction: {direction}. Use 'forward', 'back', 'left', 'right', 'up', or 'down'")

    def turn(self, direction: str, degrees: float = 90.0):
        """
        Turn agent in a direction.
        direction: "left" or "right"
        degrees: rotation amount (default 90.0)
        """
        if not self._controller:
            return

        direction = direction.lower()
        if direction == "left":
            self._controller.turn_left(degrees)
        elif direction == "right":
            self._controller.turn_right(degrees)
        else:
            print(f"Unknown turn direction: {direction}. Use 'left' or 'right'")

    def jump(self):
        """Make agent jump."""
        if self._controller:
            self._controller.jump()

    # Legacy methods for backwards compatibility
    def move_forward(self, distance: float = 1.0):
        """Move agent forward (legacy method)."""
        self.move("forward", distance)

    def turn_left(self, degrees: float = 90.0):
        """Turn agent left (legacy method)."""
        self.turn("left", degrees)

    def turn_right(self, degrees: float = 90.0):
        """Turn agent right (legacy method)."""
        self.turn("right", degrees)

    # Block manipulation API
    def place_block(self, block_name: str) -> bool:
        """Place a block in front of agent. Returns True if successful."""
        if self._interaction:
            return self._interaction.place_block(block_name)
        return False

    def break_block(self) -> bool:
        """Break the block in front of agent. Returns True if successful."""
        if self._interaction:
            return self._interaction.break_block()
        return False

    def inspect_block(self) -> dict:
        """Get info about block in front of agent."""
        if self._interaction:
            return self._interaction.inspect_block()
        return {"exists": False}

    # World sensing API
    def detect_nearby_blocks(self, radius: int = 3) -> list:
        """Detect blocks in radius around agent."""
        if self._interaction:
            return self._interaction.detect_nearby_blocks(radius)
        return []

    def get_position(self):
        """Get agent's current position."""
        if self._controller:
            return self._controller.global_position
        return None

    def get_facing_direction(self):
        """Get the direction agent is facing."""
        if self._controller:
            return self._controller.get_forward_direction()
        return None
