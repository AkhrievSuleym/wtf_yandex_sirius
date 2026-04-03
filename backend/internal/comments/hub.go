package comments

import "sync"

// Hub manages SSE subscribers per board owner.
type Hub struct {
	mu   sync.RWMutex
	subs map[string][]chan struct{}
}

func NewHub() *Hub {
	return &Hub{subs: make(map[string][]chan struct{})}
}

func (h *Hub) Subscribe(boardOwnerID string) chan struct{} {
	ch := make(chan struct{}, 1)
	h.mu.Lock()
	h.subs[boardOwnerID] = append(h.subs[boardOwnerID], ch)
	h.mu.Unlock()
	return ch
}

func (h *Hub) Unsubscribe(boardOwnerID string, ch chan struct{}) {
	h.mu.Lock()
	subs := h.subs[boardOwnerID]
	updated := make([]chan struct{}, 0, len(subs))
	for _, s := range subs {
		if s != ch {
			updated = append(updated, s)
		}
	}
	h.subs[boardOwnerID] = updated
	h.mu.Unlock()
}

// Notify sends a signal to all subscribers of a board owner (non-blocking).
func (h *Hub) Notify(boardOwnerID string) {
	h.mu.RLock()
	subs := h.subs[boardOwnerID]
	h.mu.RUnlock()
	for _, ch := range subs {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}
