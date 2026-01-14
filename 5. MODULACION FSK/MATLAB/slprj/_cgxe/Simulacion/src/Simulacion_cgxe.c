/* Include files */

#include "Simulacion_cgxe.h"
#include "m_tKCd1Jmb9SO0jWLlaIjYhH.h"

unsigned int cgxe_Simulacion_method_dispatcher(SimStruct* S, int_T method, void*
  data)
{
  if (ssGetChecksum0(S) == 938981056 &&
      ssGetChecksum1(S) == 1704697955 &&
      ssGetChecksum2(S) == 2258465670 &&
      ssGetChecksum3(S) == 2792470779) {
    method_dispatcher_tKCd1Jmb9SO0jWLlaIjYhH(S, method, data);
    return 1;
  }

  return 0;
}
