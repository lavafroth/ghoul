import asyncio
import threading
import websockets
import time
import curses
import logging

stdscr = None
logging.basicConfig(encoding='utf-8', level=logging.INFO)

async def pass_input(ws):
    global stdscr
    while True:
        try:
            ch = chr(stdscr.getch())
            await ws.send(ch)
        except (KeyboardInterrupt, EOFError):
            die()

def thunk(ws):
    asyncio.run(pass_input(ws))

def die():
    curses.nocbreak()
    curses.endwin()
    exit(0)

async def handler(ws):
    """
    Trust me, this can be improved by orders
    of magnitudes but I'm just being lazy.
    """
    thread = threading.Thread(target=thunk, args=(ws,))
    thread.start()
    while True:
        received = await ws.recv()
        decoded = received.decode()
        output = decoded.replace('\n', '\r\n')
        print(output, end="")

async def main():
    global stdscr
    host, port = "127.0.0.1", 8080
    async with websockets.serve(handler, host, port):
        stdscr = curses.initscr()
        curses.cbreak()
        await asyncio.Future()

try:
    asyncio.run(main())
except KeyboardInterrupt:
    die()
