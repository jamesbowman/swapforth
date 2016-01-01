#include <assert.h>
#include "Vj4a.h"
#include "verilated.h"
#define VCD 0
#if VCD
#include "verilated_vcd_c.h"
#endif

#define PY_SSIZE_T_CLEAN
#undef NDEBUG
#include <Python.h>

#if PY_MAJOR_VERSION >= 3
  #define MOD_ERROR_VAL NULL
  #define MOD_SUCCESS_VAL(val) val
  #define MOD_INIT(name) PyMODINIT_FUNC PyInit_##name(void)
  #define MOD_DEF(ob, name, doc, methods) \
          static struct PyModuleDef moduledef = { \
            PyModuleDef_HEAD_INIT, name, doc, -1, methods, }; \
          ob = PyModule_Create(&moduledef);
#else
  #define MOD_ERROR_VAL
  #define MOD_SUCCESS_VAL(val)
  #define MOD_INIT(name) extern "C" void init##name(void)
  #define MOD_DEF(ob, name, doc, methods) \
          ob = Py_InitModule3(name, methods, doc);
#endif

typedef struct {
    PyObject_HEAD
    /* Type-specific fields go here. */
    Vj4a* dut;
    int ddepth[4096], rdepth[4096];
#if VCD
    VerilatedVcdC* tfp;
#endif
} v3;

static void
Vj4a_dealloc(v3* self)
{
#if VCD
  if (self->tfp) {
    self->tfp->close();
  }
#endif
  delete self->dut;
  Py_TYPE(self)->tp_free((PyObject*)self);
}

static int
Vj4a_init(v3 *self, PyObject *args, PyObject *kwds)
{
  self->dut = new Vj4a;
  FILE *hex = fopen("../build/nuc.hex", "r");
  int i;
  for (i = 0; i < 4096; i++) {
    unsigned int v;
    if (fscanf(hex, "%x\n", &v) != 1) {
      fprintf(stderr, "invalid hex value at line %d\n", i + 1);
      exit(1);
    }
    self->dut->v__DOT__ram_prog[i] = v;
  }
  memset(self->rdepth, 0, sizeof(self->rdepth));
  memset(self->ddepth, 0, sizeof(self->ddepth));

  return 0;
}

#if VCD
PyObject *v3_vcd(PyObject *_, PyObject *args)
{
  v3 *self = (v3*)_;
  int sense;
  if (!PyArg_ParseTuple(args, "I", &sense))
    return NULL;

  if (sense) {
    self->tfp = new VerilatedVcdC;
    self->dut->trace(self->tfp, 99);
    self->tfp->open("j4a.vcd");
  } else {
    self->tfp->close();
    self->tfp = NULL;
  }
  Py_RETURN_NONE;
}
#endif

PyObject *v3_reset(PyObject *self, PyObject *args)
{
  // Py_BEGIN_ALLOW_THREADS
  ((v3*)self)->dut->resetq = 0;
  ((v3*)self)->dut->eval();
  ((v3*)self)->dut->resetq = 1;
  // Py_END_ALLOW_THREADS
  Py_RETURN_NONE;
}

PyObject *v3_inWaiting(PyObject *self, PyObject *args)
{
#if PY_MAJOR_VERSION < 3
  return PyInt_FromLong(1);
#else
  return PyLong_FromLong(1);
#endif
}

PyObject *v3_profile(PyObject *self, PyObject *args)
{
  v3* v = (v3*)self;
  int i;

  PyObject *r = PyList_New(4096);
  for (i = 0; i < 4096; i++)
    PyList_SET_ITEM(r, i, PyLong_FromLong(v->rdepth[i]));
  return r;
}

static void cycle(v3* v)
{
  Vj4a* dut = v->dut;
  dut->clk = 0;
  dut->eval();
  dut->clk = 1;
  dut->eval();

  int pc = dut->v__DOT___j4__DOT__pc;
  if (pc < 4096) {
    if (dut->v__DOT___j4__DOT__dstack___DOT__depth > v->ddepth[pc])
      v->ddepth[pc] = dut->v__DOT___j4__DOT__dstack___DOT__depth;
    if (dut->v__DOT___j4__DOT__rstack___DOT__depth > v->rdepth[pc])
      v->rdepth[pc] = dut->v__DOT___j4__DOT__rstack___DOT__depth;
  }
}

PyObject *v3_read(PyObject *_, PyObject *args)
{
  Vj4a* dut = ((v3*)_)->dut;
  int count;
  if (!PyArg_ParseTuple(args, "I", &count))
    return NULL;

  Py_ssize_t len = count;
  char buf[len];

  for (int i = 0; i < count; i++) {
    do {
      if (PyErr_CheckSignals())
        return NULL;
      cycle((v3*)_);
    } while (dut->uart0_wr == 0);
    buf[i] = dut->uart_w;
  }

#if PY_MAJOR_VERSION < 3
  return PyString_FromStringAndSize(buf, len);
#else
  return PyBytes_FromStringAndSize(buf, len);
#endif
}

PyObject *v3_write(PyObject *_, PyObject *args)
{
  Vj4a* dut = ((v3*)_)->dut;
  const char *s;
  Py_ssize_t n;
  if (!PyArg_ParseTuple(args, "s#", &s, &n))
    return NULL;

  for (Py_ssize_t i = 0; i < n; i++) {
    dut->uart0_data = s[i];
    dut->uart0_valid = 1;
    do {
      if (PyErr_CheckSignals())
        return NULL;
      cycle((v3*)_);
    } while (dut->uart0_rd == 0);
    do {
      if (PyErr_CheckSignals())
        return NULL;
      cycle((v3*)_);
    } while (dut->uart0_rd == 1);
  }

  dut->uart0_valid = 0;
  Py_RETURN_NONE;
}

static PyMethodDef Vj4a_methods[] = {
    {"reset", v3_reset, METH_NOARGS},
    {"read", v3_read, METH_VARARGS},
    {"write", v3_write, METH_VARARGS},
    {"inWaiting", v3_inWaiting, METH_NOARGS},
    {"profile", v3_profile, METH_NOARGS},
    {NULL}  /* Sentinel */
};

static PyTypeObject v3_V3Type = {
    PyVarObject_HEAD_INIT(NULL, 0)
    "parts.v3", /*tp_name*/
    sizeof(v3),               /*tp_basicsize*/
    0,                        /*tp_itemsize*/
    (destructor)Vj4a_dealloc,                        /*tp_dealloc*/
    0,                        /*tp_print*/
    0,                        /*tp_getattr*/
    0,                        /*tp_setattr*/
    0,                        /*tp_compare*/
    0,                        /*tp_repr*/
    0,                        /*tp_as_number*/
    0,                        /*tp_as_sequence*/
    0,                        /*tp_as_mapping*/
    0,                        /*tp_hash */
    0,                        /*tp_call*/
    0,                        /*tp_str*/
    0,                        /*tp_getattro*/
    0,                        /*tp_setattro*/
    0,                        /*tp_as_buffer*/
    Py_TPFLAGS_DEFAULT | Py_TPFLAGS_BASETYPE,        /*tp_flags*/
    "Vj4a objects",             /* tp_doc */
    0,                        /* tp_traverse */
    0,                        /* tp_clear */
    0,                        /* tp_richcompare */
    0,                        /* tp_weaklistoffset */
    0,                        /* tp_iter */
    0,                        /* tp_iternext */
    Vj4a_methods,               /* tp_methods */
    0,                        /* tp_members */
    0,                        /* tp_getset */
    0,                        /* tp_base */
    0,                        /* tp_dict */
    0,                        /* tp_descr_get */
    0,                        /* tp_descr_set */
    0,                        /* tp_dictoffset */
    (initproc)Vj4a_init,        /* tp_init */
    0,                        /* tp_alloc */
    0,                        /* tp_new */
};

MOD_INIT(vsimj4a)
{
  PyObject *m;

  v3_V3Type.tp_new = PyType_GenericNew;
  if (PyType_Ready(&v3_V3Type) < 0)
      return MOD_ERROR_VAL;

#if VCD
  Verilated::traceEverOn(true);
#endif

  MOD_DEF(m, "vsimj4a", "", NULL)

  Py_INCREF(&v3_V3Type);
  PyModule_AddObject(m, "vsimj4a", (PyObject *)&v3_V3Type);
  return MOD_SUCCESS_VAL(m);
}
