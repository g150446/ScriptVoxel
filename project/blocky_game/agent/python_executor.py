# Python code executor that runs user code with py4godot
# This script is loaded by Godot and can execute dynamic Python code

from godot import exposed, export
from godot.classdb import Node
import sys
from io import StringIO


@exposed
class PythonExecutor(Node):
    """
    Executes user Python code dynamically within the py4godot environment.
    """

    def __init__(self):
        super().__init__()
        self.agent = None
        self.output_buffer = []

    def set_agent(self, agent_api):
        """Set the agent API reference that will be available to user code"""
        self.agent = agent_api

    def execute_code(self, code_string: str) -> dict:
        """
        Execute Python code string and return results.
        Returns dict with 'success', 'output', and 'error' keys.
        """
        self.output_buffer = []

        # Redirect stdout to capture print statements
        old_stdout = sys.stdout
        sys.stdout = StringIO()

        result = {
            'success': False,
            'output': [],
            'error': ''
        }

        try:
            # Create execution environment with agent available
            exec_globals = {
                'agent': self.agent,
                '__builtins__': __builtins__
            }

            # Execute the user code
            exec(code_string, exec_globals)

            # Capture output
            output = sys.stdout.getvalue()
            if output:
                result['output'] = output.split('\n')

            result['success'] = True

        except SyntaxError as e:
            result['error'] = f"Syntax Error on line {e.lineno}: {e.msg}"
        except NameError as e:
            result['error'] = f"Name Error: {str(e)}"
        except AttributeError as e:
            result['error'] = f"Attribute Error: {str(e)}"
        except Exception as e:
            result['error'] = f"Error: {type(e).__name__}: {str(e)}"
        finally:
            # Restore stdout
            sys.stdout = old_stdout

        return result
