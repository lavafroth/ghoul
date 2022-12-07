import asyncio
import threading
import websockets
import time

async def pass_input(ws):
    time.sleep(1)
    while True:
        await ws.send(input(''))

def thunk(ws):
    asyncio.run(pass_input(ws))

async def handler(ws):
    """
    Trust me, this can be improved by orders
    of magnitudes but I'm just being lazy.
    """
    thread = threading.Thread(target=thunk, args=(ws,))
    thread.start()
    while True:
        try:
            print((await ws.recv()).decode(), end="")
        except KeyboardInterrupt:
            print("ok bye")
            return

async def main():
    async with websockets.serve(handler, "127.0.0.1", 8080):
        await asyncio.Future()

asyncio.run(main())
