#include <assert.h>
#include "Vj1a.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define PY_SSIZE_T_CLEAN
#undef NDEBUG
#include <Python.h>

#define VCD 1

typedef struct {
    PyObject_HEAD
    /* Type-specific fields go here. */
    Vj1a* dut;
    VerilatedVcdC* tfp;
} v3;

static void
Vj1a_dealloc(v3* self)
{
  if (self->tfp) {
    self->tfp->close();
  }
  delete self->dut;
  self->ob_type->tp_free((PyObject*)self);
}

static int
Vj1a_init(v3 *self, PyObject *args, PyObject *kwds)
{
  self->dut = new Vj1a;
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

  return 0;
}

PyObject *v3_vcd(PyObject *_, PyObject *args)
{
  v3 *self = (v3*)_;
  int sense;
  if (!PyArg_ParseTuple(args, "I", &sense))
    return NULL;

  if (sense) {
    self->tfp = new VerilatedVcdC;
    self->dut->trace(self->tfp, 99);
    self->tfp->open("j1a.vcd");
  } else {
    self->tfp->close();
    self->tfp = NULL;
  }
  Py_RETURN_NONE;
}

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
  return PyInt_FromLong(1);
}

#define CYCLE() (dut->clk = 0, dut->eval(), dut->clk = 1, dut->eval())

PyObject *v3_read(PyObject *_, PyObject *args)
{
  Vj1a* dut = ((v3*)_)->dut;
  int count;
  if (!PyArg_ParseTuple(args, "I", &count))
    return NULL;

  Py_ssize_t len = count;
  char buf[len];

  for (int i = 0; i < count; i++) {
    do {
      if (PyErr_CheckSignals())
        return NULL;
      CYCLE();
    } while (dut->uart0_wr == 0);
    buf[i] = dut->uart_w;
  }

  return PyString_FromStringAndSize(buf, len);
}

PyObject *v3_write(PyObject *_, PyObject *args)
{
  Vj1a* dut = ((v3*)_)->dut;
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
      CYCLE();
    } while (dut->uart0_rd == 0);
    do {
      if (PyErr_CheckSignals())
        return NULL;
      CYCLE();
    } while (dut->uart0_rd == 1);
  }

  dut->uart0_valid = 0;
  Py_RETURN_NONE;
}

static PyMethodDef Vj1a_methods[] = {
    {"reset", v3_reset, METH_NOARGS},
    {"read", v3_read, METH_VARARGS},
    {"write", v3_write, METH_VARARGS},
    {"inWaiting", v3_inWaiting, METH_NOARGS},
    {NULL}  /* Sentinel */
};

static PyTypeObject v3_V3Type = {
    PyObject_HEAD_INIT(NULL)
    0,                        /*ob_size*/
    "parts.v3", /*tp_name*/
    sizeof(v3),               /*tp_basicsize*/
    0,                        /*tp_itemsize*/
    (destructor)Vj1a_dealloc,                        /*tp_dealloc*/
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
    "Vj1a objects",             /* tp_doc */
    0,                        /* tp_traverse */
    0,                        /* tp_clear */
    0,                        /* tp_richcompare */
    0,                        /* tp_weaklistoffset */
    0,                        /* tp_iter */
    0,                        /* tp_iternext */
    Vj1a_methods,               /* tp_methods */
    0,                        /* tp_members */
    0,                        /* tp_getset */
    0,                        /* tp_base */
    0,                        /* tp_dict */
    0,                        /* tp_descr_get */
    0,                        /* tp_descr_set */
    0,                        /* tp_dictoffset */
    (initproc)Vj1a_init,        /* tp_init */
    0,                        /* tp_alloc */
    0,                        /* tp_new */
};

extern "C" void initvsimj1a()
{
  PyObject *m;

  v3_V3Type.tp_new = PyType_GenericNew;
  if (PyType_Ready(&v3_V3Type) < 0)
      return;

  Verilated::traceEverOn(true);
  m = Py_InitModule("vsimj1a", NULL);

  Py_INCREF(&v3_V3Type);
  PyModule_AddObject(m, "vsimj1a", (PyObject *)&v3_V3Type);

  m = Py_InitModule("parts", NULL);
}
