import asyncio
from typing import Dict, List


class SSEManager:
    def __init__(self) -> None:
        self.subscribers: Dict[int, List[asyncio.Queue]] = {}
        self.lock = asyncio.Lock()

    async def subscribe(self, player_id: int) -> asyncio.Queue:
        queue = asyncio.Queue()
        async with self.lock:
            if player_id not in self.subscribers:
                self.subscribers[player_id] = []
            self.subscribers[player_id].append(queue)

        return queue

    async def unsubscribe(self, player_id: int, queue: asyncio.Queue):
        async with self.lock:
            if player_id in self.subscribers:
                if queue in self.subscribers[player_id]:
                    self.subscribers[player_id].remove(queue)

                # verifica si la lista esta vacia
                if not self.subscribers[player_id]:
                    del self.subscribers[player_id]

    async def broadcast(self, player_id: int, event: str, data: dict):

        message = {"event": event, "data": data}

        async with self.lock:
            if player_id not in self.subscribers:
                return

            queues = self.subscribers[player_id]

            for queue in queues:
                await queue.put(message)


sse_manager = SSEManager()
