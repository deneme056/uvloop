@cython.final
@cython.internal
cdef class UVIdle(UVHandle):
    def __cinit__(self, Loop loop, object callback):
        cdef int err

        self._handle = <uv.uv_handle_t*> \
                            PyMem_Malloc(sizeof(uv.uv_idle_t))
        if self._handle is NULL:
            raise MemoryError()

        self._handle.data = <void*> self

        err = uv.uv_idle_init(loop.loop, <uv.uv_idle_t*>self._handle)
        if err < 0:
            raise convert_error(err)

        self.callback = callback
        self.running = 0

    cdef stop(self):
        cdef int err

        self.ensure_alive()

        if self.running == 1:
            err = uv.uv_idle_stop(<uv.uv_idle_t*>self._handle)
            self.running = 0
            if err < 0:
                raise convert_error(err)

    cdef start(self):
        cdef int err

        self.ensure_alive()

        if self.running == 0:
            err = uv.uv_idle_start(<uv.uv_idle_t*>self._handle,
                                   cb_idle_callback)
            if err < 0:
                raise convert_error(err)
            self.running = 1


cdef void cb_idle_callback(uv.uv_idle_t* handle) with gil:
    cdef UVIdle idle = <UVIdle> handle.data
    try:
        idle.callback()
    except BaseException as ex:
        idle._loop._handle_uvcb_exception(ex)
