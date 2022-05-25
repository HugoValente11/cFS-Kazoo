#!/usr/bin/env python3
#
# TASTE Automatically generated file...You may edit at will.
# ----------------------------------------------------------------------------
import os
import sys
import time
import signal
import queue
from PySide2.QtCore                  import QCoreApplication, Qt
# ----------------------------------------------------------------------------
from asn1_value_editor.Scenario      import Scenario, PollerThread
from asn1_value_editor.udpcontroller import tasteUDP
# ----------------------------------------------------------------------------
#  You may edit the scenario below or create new ones (@Scenario decorator)
#  When you add new scenarios, they will all run in parallel.
#
#  You can use these three API functions to communicate with the main binary:
#  (1) queue.sendMsg('Name of Provided Interface', 'Parameter')
#          The parameters are expressed textually in ASN.1 Value Notation
#          (also called GSER). For example a record's syntax is:
#          { fieldName1 value1, fieldName2 value2 }
#  (2) queue.expectMsg ('Name of RI',
#                       'Parameter value in Extended ASN.1 format',
#                       lineNo=optional line reference,
#                       ignoreOther=True/False)
#          Extended ASN.1 format lets you replace a field value with a star (*)
#          meaning that you do not want the tool to check it against any
#          specific value
#          ignoreOther: set True if you want the tool to ignore other messages
#                       and want to trigger an error only when you get this
#                       message with the wrong parameters
# (3) (msgId, val) = queue.getNextMsg(timeout=10)
#      if msgId == 'Name of an interface':
#          print 'The value is', val.fieldName.Get()
# ----------------------------------------------------------------------------
# First document
# from the section : mscdocument Untitled_Document
# Type of MSC: AND
# PI1 (T-Null-Record)
# start_ada_timer (T-Null-Record)
# start_sdl_timer (T-Null-Record)
# Ada_Timer_Expired (T-Null-Record)
# C_Timer_Expired (T-Null-Record)
# SDL_Timer1_Expired (T-Null-Record)
# SDL_Timer2_Expired (T-Null-Record)
# ----------------------------------------------------------------------------
# from the section : mscdocument Untitled_Leaf
# Type of MSC: LEAF
# ----------------------------------------------------------------------------
# msc Untitled_MSC;
@Scenario
def Exercise_gui(queue):
   queue.sendMsg('start_ada_timer', '''{}''')
   queue.expectMsg('Ada_Timer_Expired', '''{}''', ignoreOther=False)
   queue.sendMsg('PI1', '''{}''')
   queue.expectMsg('C_Timer_Expired', '''{}''', ignoreOther=False)
   queue.sendMsg('start_sdl_timer', '''{}''')
   queue.expectMsg('SDL_Timer1_Expired', '''{}''', ignoreOther=False)
   queue.expectMsg('SDL_Timer2_Expired', '''{}''', ignoreOther=False)
# Entry point
def runScenario(pipe_in=None, pipe_out=None, udpController=None):
    # Queue for getting scenario status
    log = queue.Queue()
    if udpController:
        gui = Exercise_gui(log, name='Exercise_gui')
        udpController.slots.append(gui.msq_q)
        gui.wait()
        udpController.slots.remove(gui.msg_q)
        return 0 # gui.status
    else:
    # Use message queue (TASTE default)
        poller = PollerThread()
        gui = Exercise_gui(log, name='Exercise_gui')
        poller.slots.append(gui.msg_q)
        poller.start()
        gui.start()
        # Wait and log messages from both scenarii
        while True:
            time.sleep(0.001)
            try:
                scenario, severity, msg = log.get(block=False)
            except queue.Empty:
                pass
            else:
                log.task_done()
                try:
                    # If called from the GUI, send log through pipe
                    pipe_out.send((scenario, severity, msg))
                except AttributeError:
                    print('[{level}] {name} - {msg}'.format
                        (level=severity, name=scenario, msg=msg))
                if severity == 'ERROR' or msg == 'END':
                    # Stop execution on first error or completed scenario
                    try:
                        # send to GUI
                        pipe_out.send(('All', 'COMMAND', 'END'))
                    except AttributeError:
                        gui.stop()
                        poller.stop()
                        if severity == 'ERROR':
                            return 1
                        else:
                            return 0
                try:
                    if pipe_out.poll():
                        cmd = pipe_out.recv()
                        if cmd == 'STOP':
                            gui.stop()
                            poller.stop()
                            return 0
                except AttributeError:
                    pass


# End of first document
# Entry point when scenario is executed from the command line
if __name__ == "__main__":
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    udpController = None
    if '--udp' in sys.argv:
        # Create UDP Controller with default IP/Port values (127.0.0.1:7755:7756)
        udpController = tasteUDP()
    QCoreApplication(sys.argv)
    sys.exit(runScenario(udpController))