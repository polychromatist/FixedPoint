-- polychromatist
-- DEPENDENCIES: @kikito/middleclass
-- see _notes file for more information. notes may be referenced in comments.

-- IMPORTANT: fixed point values themselves are doubles, with the property math.floor(d) == d.
--            creating a new instance of FixedPoint assigns these integers radix points, aka a decimal point.
--            this is called a fixed point context. using it, you can do operations as if the radix point were really there.

   local extpaths = {}
   -- Add below the path to middleclass library
   -- On ROBLOX, you may have a ModuleScript anywhere and an ObjectValue whose Value points to that ModuleScript
   local mclasspath
   if game then
      local R = game:GetService("ReplicatedStorage")
      if not mclasspath then
         if script:FindFirstChild("ClassPath") then
            mclasspath = script.ClassPath.Value
         elseif R:FindFirstChild("Path") and R.Path:FindFirstChild("Class") then
            mclasspath = R.Path.Class.Value
         elseif R:FindFirstChild("middleclass") then
            mclasspath = game.ReplicatedStorage.middleclass
         else
            error("FixedPoint: could not find 'middleclass' library. Parent as ModuleScript to ReplicatedStorage or see module source for alternative resolution.")
         end
      end
   else
      mclasspath = mclasspath or "middleclass"
   end
   
   local class = require(mclasspath)
   if class._VERSION ~= "middleclass v4.1.1" then
      (warn or print)("FixedPoint: warning: class version mismatch (got '" .. class._VERSION .. "', expected 'middleclass v4.1.1')")
   end
   
   _IGNORE_OVERFLOW_DEFAULT = false
   -- zero or one, zero to mask out warnings, one (default) to keep them
   _PRINTLEVEL = 1
   -- zero or one, zero (default) to neglect input validity checks, one to keep them
   -- does not mean output validity checks will be neglected. set _IGNORE_OVERFLOW_DEFAULT for that, or use the function parameter ignoreOverflow
   _ERRORLEVEL = 1
   -- _MAX_RADIUS: note A1
   _MAX_RADIUS = 14
   
   
   -- if you want to overload this, write a module with a method named "RAND_FN" according to the "randfn" specification, see #genRand() for that
   local _DEFAULT_RAND_FN
   do
      local random = math.random
      _DEFAULT_RAND_FN = function(self)
         return random(-99999999, 99999999) + random(-9999999, 9999999) * 1e8
      end
   end
   
   local function assert_int(name, value, origin)
      -- conserve nan(ind)
      origin = origin or "FixedPoint"
      if (value == value) then
         if type(value) ~= "number" then
            error(origin .. ": the type for "..name.." must be a number (got ".. type(value) ..")")
         elseif math.floor(value) ~= value then
            error(origin .. ": the type for "..name.." must be an integer")
         end
      end
   end
   
   local fmod, abs, sign = math.fmod, math.abs, math.sign
   if not sign then
      sign = function(x)
         return x > 0 and 1 or x < 0 and -1 or 0
      end
   end
   local MAX_OVERFLOW_VAL = math.pow(10, _MAX_RADIUS)
   
   -- underlying function for FixedPoint#asValue
   local function as_value(self, int, frac, policy)
      policy = policy or self.ROUND_POLICY
      
      if self.RADIX_POINT == 6 then
         return int * self.RADIX_RHS_VAL + frac
      end
      -- least significant digit right-hand-side value
      local lsdrhsv = math.pow(10, 6 - self.RADIX_POINT)
      local frac_virt = fmod(frac, lsdrhsv)
      local frac_real = (frac - frac_virt) / lsdrhsv
      frac_virt = frac_virt * self.RADIX_RHS_VAL
      frac_virt = (frac_virt - fmod(frac_virt, lsdrhsv)) / lsdrhsv
      return self:lsdRound(int * self.RADIX_RHS_VAL + frac_real, frac_virt, policy)
   end
   
   
   -- FixedPoint class: note A2
   local FixedPoint = class("FixedPoint")
   
   FixedPoint.static._VERSION = "FixedPoint v1.0.0"
   FixedPoint.static.IGN_OVF = _IGNORE_OVERFLOW_DEFAULT
   FixedPoint.static.MAX_OVF_VAL = MAX_OVERFLOW_VAL
   
   -- RADIUS positive integer: note A3
   -- RADIX_POINT positive integer: note A4
   -- ROUND_POLICY string or function: note A5
   function FixedPoint:initialize(RADIUS, RADIX_POINT, ROUND_POLICY)
      assert_int("RADIUS", RADIUS)
      assert(3 < RADIUS, "FixedPoint: RADIUS must be more than three (internal functionality limit)")
      if _PRINTLEVEL > 0 and RADIUS < 9 then
         (warn or print)("FixedPoint: functionality may be affected with small RADIUS choices")
      end
      assert(RADIUS <= _MAX_RADIUS, "FixedPoint: RADIUS must not exceed limit (see RADIUS note A3)")
      
      assert_int("RADIX_POINT", RADIX_POINT)
      assert(0 < RADIX_POINT, "FixedPoint: RADIX_POINT must be more than zero")
      assert(RADIX_POINT + 3 <= RADIUS, "FixedPoint: RADIX_POINT is out of bounds (got ".. RADIX_POINT ..", need less than " .. RADIUS - 3 ..")")
      
      assert(RADIX_POINT <= 6, "FixedPoint: RADIX_POINT is too large, see note A6")
      
      local policy
      if type(ROUND_POLICY) == "string" then
         policy = FixedPoint.static.ROUND_POLICY[ROUND_POLICY]
         assert(policy, "FixedPoint: Could not create; ROUND_POLICY is invalid (got enum '"..ROUND_POLICY.."')")
         self.ROUND_POLICY = ROUND_POLICY
      else
         assert(type(ROUND_POLICY) == "function", "FixedPoint: Could not create; ROUND_POLICY has incorrect type (got type '"..type(ROUND_POLICY).."')")
         self.ROUND_POLICY = "CUSTOM"
      end
         
      local policy = FixedPoint.static.ROUND_POLICY[ROUND_POLICY]
      
      self.RADIUS = RADIUS
      self.RADIX_POINT = RADIX_POINT
      -- OVERFLOW_VAL contains the smallest number where the RADIUS is too large
      self.OVERFLOW_VAL = math.pow(10, RADIUS)
      -- RADIX_RHS_VAL: note A7
      self.RADIX_RHS_VAL = math.pow(10, RADIX_POINT)
      self.RAND_FN = _DEFAULT_RAND_FN
      
      if type(ROUND_POLICY) == "function" then
         self.ROUND_FN = ROUND_POLICY
      else
         self.ROUND_FN = function(self, int, frac, RHS_VAL)
            return self:mustEnlarge(policy, int, frac, RHS_VAL)
         end
      end
      
      local function av(int, frac)
         return as_value(self, int, frac)
      end
      
      -- these constants are for your convenience, but are also used in implementation
      self.CONSTANT = {
         -- note that i have 'rounded' TAU here manually for sanity at radix 6, where it is likely to be used
         -- that is to say, TAU is in reality meant to be 6.283185
         TAU = av(6, 283186),
         PI = av(3, 141593),
         -- (deg)rees in one (r)evolution
         DEGR = 360 * self.RADIX_RHS_VAL,
         E = av(2, 718282),
         E_INV = av(0, 367879),
         HALF = av(0, 500000),
         HALFPI = av(1, 570797),
         FOURTHPI = av(0, 785398),
         LN2 = av(0, 693147),
         SQRT2 = av(1, 414214),
         TWO = 2 * self.RADIX_RHS_VAL,
         TEN = 10 * self.RADIX_RHS_VAL
      }
      
      -- these constants are not useful in general, but happen to be used in implementation
      self._INTERNALS = {
         -- used for binary logarithm implementation
         RECIP_LN2 = av(1, 442695),
         -- used for sqrt, threshold for overflow-producing roots (sqrt(OVERFLOW_VAL))
         OVF_SQRT = (function(N)
            if self.RADIUS % 2 == 1 then
               N = self:mult(N, av(3, 162278))
            end
            return N
         end)(math.pow(10, self.RADIX_POINT + math.floor((self.RADIUS - self.RADIX_POINT) / 2))),
         -- same as above in the case of max radius
         MAX_OVF_SQRT = (function(N)
            if _MAX_RADIUS % 2 == 1 then
               N = self:mult(N, av(3, 162278))
            end
            return N
         end)(math.pow(10, self.RADIX_POINT + math.floor((_MAX_RADIUS - self.RADIX_POINT) / 2))),
         -- and finally in case of 9e15-producing roots (even integer very close to FLINTMAX, 2^52)
         FLINTMAX_OVF_SQRT = (function(N)
            if (15 - self.RADIX_POINT) % 2 == 1 then
               N = self:mult(N, av(3, 162278))
            end
            return 3 * N
         end)(math.pow(10, self.RADIX_POINT + math.floor((15 - self.RADIX_POINT) / 2))), 
         -- following two values used for sqrt. optimal choice of base multiplier for estimating first choice in newton approximation
         -- see the sqrt implementation for details
         FOUR_THIRDS_ROOT_2 = av(1, 681792),
         FOURTH_ROOT_2 = av(1, 189207),
         -- following two used for fractional lg implementation
         EIGHTYFOUR = 84 * self.RADIX_RHS_VAL,
         SEVENTY = 70 * self.RADIX_RHS_VAL,
         -- used for division
         RADIX_LHS_VAL = self.RADIX_RHS_VAL / 10,
         -- atan implementation
         ATAN_TERM1 = av(0, 327623),
         -- used for exp overflow guarding
         EXP_OVF = av(34, 434200)
         
      }
      
      self.LOOKUP = {
         -- powers of two scaled by one
         POWERS_OF_TWO_SCALED_ONE = (function(ret)
            for i = 0, 40 do
               local pot_i = 2^i * self.RADIX_RHS_VAL
               if pot_i > 9e15 then
                  break
               end
               ret[i] = pot_i
            end
            return ret
         end){},
         -- powers of two scaled by the four-thirds-root of 2
         POWERS_OF_TWO_SCALED_FTR2 = (function(ret)
            for i = 0, 40 do
               local pot_i = 2^i * self._INTERNALS.FOUR_THIRDS_ROOT_2
               if pot_i > 9e15 then
                  break
               end
               ret[i] = pot_i
            end
            return ret
         end){},
         -- powers of two scaled by fourth root of 2
         POWERS_OF_TWO_SCALED_FR2 = (function(ret)
            for i = 0, 40 do
               local pot_i = 2^i * self._INTERNALS.FOURTH_ROOT_2
               if pot_i > 9e15 then
                  break
               end
               ret[i] = pot_i
            end
            return ret
         end){},
         -- unscaled powers of two
         POWERS_OF_TWO = (function(ret)
            for i = 0, 40 do
               local pot_i = 2^i * self.RADIX_RHS_VAL
               if pot_i * self.RADIX_RHS_VAL > 9e15 then
                  break
               end
               ret[i] = pot_i
            end
            return ret
         end){},
         -- powers of two scaled by four-thirds-root 2, and then inverted
         INV_POWERS_OF_TWO_SCALED_FTR2 = (function(ret)
            for i = 0, 20 do
               local invpot_i = self:div(self.RADIX_RHS_VAL, 2^i * self._INTERNALS.FOUR_THIRDS_ROOT_2, "HALF_TO_EVEN")
               if invpot_i == 0 then
                  break
               end
               ret[i] = invpot_i
            end
            return ret
         end){},
         -- powers of two scaled by fourth root 2, and then inverted
         INV_POWERS_OF_TWO_SCALED_FR2 = (function(ret)
            for i = 0, 20 do
               local invpot_i = self:div(self.RADIX_RHS_VAL, 2^i * self._INTERNALS.FOURTH_ROOT_2, "HALF_TO_EVEN")
               if invpot_i == 0 then
                  break
               end
               ret[i] = invpot_i
            end
            return ret
         end){},
         POWERS_OF_TEN = (function(ret)
            for i = 0,14 do
               ret[i] = 10^i
            end
            return ret
         end){},
         -- powers of ten scaled by one, including all expressible inverse powers of ten as negative indices
         POWERS_OF_TEN_SCALED_ONE = (function(ret)
            for i = -self.RADIX_POINT,_MAX_RADIUS-self.RADIX_POINT do
               ret[i] = 10^(i + self.RADIX_POINT)
            end
            return ret
         end){}
      }
      
   end
   
   -- ROUND_POLICY will be used on #mult(), #div()
   FixedPoint.static.ROUND_POLICY = {
      -- go look on wikipedia's Rounding article for information about how these work.
      -- ALTERNATIVELY, see the implementation for #mustEnlarge()
      HALF_AWAY_FROM_ZERO = 0,
      NEXT_INT = 1,
      LAST_INT = 2,
      HALF_UP = 3,
      HALF_DOWN = 4,
      HALF_TO_EVEN = 5,
      HALF_TOWARDS_ZERO = 6,
      CUSTOM = 99
   }
   
   -- this will enforce that the given raw value is valid within this fixed point context
   function FixedPoint:assert_valid(name, raw)
      assert_int(name, raw)
      assert(not self:chk_overflow(raw), "FixedPoint: "..name.." has a value that is over RADIUS ("..name..": "..math.floor(math.log(raw)/math.log(10))..", RADIUS: "..self.RADIUS..")")
   end
   
   -- this will return a boolean of whether the result has overflowed (e.g. if radius is 8, 10^9 or larger is overflow)
   function FixedPoint:chk_overflow(raw)
      -- admit math.huge, admit nan(ind)
      --   this is admitted for division to be consistent with the corresponding native Lua ops
      return (raw ~= math.huge) and (raw == raw) and (raw >= self.OVERFLOW_VAL or raw <= -self.OVERFLOW_VAL)
   end
   
   -- split virtual integer and fractional parts into two integers, following the fixed point context
   -- if the integer is positive, the split results will both be positive. if negative, it will instead both be negative.
   -- similar to math.modf
   function FixedPoint:split(raw)
      assert_int("raw", raw)
      
      local int1 = raw - fmod(raw, self.RADIX_RHS_VAL)
      
      return int1, int1 == 0 and raw or raw - int1
   end
   
   function FixedPoint:splitAt(raw, i)
      assert_int("raw", raw)
      assert_int("i", i)
      assert(i < self.RADIUS and i > 0, "FixedPoint: i out of bounds error (got " .. self:toString(i) .. ")")
      
      local int1 = fmod(raw, (self.LOOKUP and self.LOOKUP.POWERS_OF_TEN[i] or 10^i))
      local int0 = raw - int1
      
      return int0, int1
   end
   
   -- operations for plus, minus are just wrappers of the base Lua operations
   -- you can add or subtract fixed point values with + and - directly
   function FixedPoint:add(raw1, raw2, ignoreOverflow, errorlevel)
      if ignoreOverflow == nil then
         ignoreOverflow = _IGNORE_OVERFLOW_DEFAULT
      end
      
      if (errorlevel or _ERRORLEVEL) > 0 then
         self:assert_valid("raw1", raw1)
         self:assert_valid("raw2", raw2)
      end
      local result = raw1 + raw2
      
      if not ignoreOverflow and self:chk_overflow(result) then
         error("FixedPoint: OVERFLOW (addition). op1: "..raw1.." op2: "..raw2..".")
      end
      return raw1 + raw2
   end
   
   function FixedPoint:sub(raw1, raw2, ignoreOverflow, errorlevel)
      if ignoreOverflow == nil then
         ignoreOverflow = _IGNORE_OVERFLOW_DEFAULT
      end
      
      if (errorlevel or _ERRORLEVEL) > 0 then
         self:assert_valid("raw1", raw1)
         self:assert_valid("raw2", raw2)
      end
      local result = raw1 - raw2
      
      if not ignoreOverflow and self:chk_overflow(result) then
         error("FixedPoint: OVERFLOW (subtraction). op1: "..raw1.." op2: "..raw2..".")
      end
      return raw1 - raw2
   end
   
   -- FixedPoint#mult() method: note A8
   -- important tip:
   --   if you are multiplying a fixed point value V with a Lua integer N, it will work to write N * V.
   --   for example, if you just want three times your value V = 0054.342, you can write 3 * V and it will work great.
   function FixedPoint:mult(raw1, raw2, policy, ignoreOverflow, errorlevel)
      if ignoreOverflow == nil then
         ignoreOverflow = _IGNORE_OVERFLOW_DEFAULT
      end
      if (errorlevel or _ERRORLEVEL) > 0 then
         self:assert_valid("raw1", raw1)
         self:assert_valid("raw2", raw2)
      end
      
      policy = policy or self.ROUND_POLICY
      
      if (raw1 >= 0 and raw1 or -raw1) < 1e7 and (raw2 >= 0 and raw2 or -raw2) < 1e7 then
         return self:round(raw1 * raw2, policy) / self.RADIX_RHS_VAL
      end
      
      local int1
      
      local s1int1, s1int2 = self:splitAt(raw1, 7)
      local s2int1, s2int2 = self:splitAt(raw2, 7)
      
      local off = self.LOOKUP and self.LOOKUP.POWERS_OF_TEN[7 - self.RADIX_POINT] or 10^(7 - self.RADIX_POINT)
      
      -- taking upper parts out of fixed point context
      s1int1 = s1int1 / 1e7
      s2int1 = s2int1 / 1e7
      
      int1 = (s1int1 * s2int1) * 1e7
      
      local result
      if s1int2 == 0 and s2int2 == 0 then
         result = int1 * off
      elseif s1int2 == 0 then
         result = off * (int1 + s1int1 * s2int2)
      elseif s2int2 == 0 then
         result = off * (int1 + s2int1 * s1int2)
      else
         result = off * (int1 + s1int1 * s2int2 + s1int2 * s2int1) + self:round(s1int2 * s2int2, policy) / self.RADIX_RHS_VAL
      end
      
      if not ignoreOverflow and self:chk_overflow(result) then
         error("FixedPoint: OVERFLOW (multiplication). op1: "..raw1.." op2: "..raw2..".")
      end
      
      return result
   end
   
   -- FixedPoint#multOvf() function: note B6
   function FixedPoint:multOvf(raw1, raw2, policy)
      assert_int("raw1", raw1)
      assert_int("raw2", raw2)
      
      if _ERRORLEVEL > 0 then
         self:assert_valid("raw1", raw1)
         self:assert_valid("raw2", raw2)
      end
      
      policy = policy or self.ROUND_POLICY
      
      local int1
      
      local s1int1, s1int2 = self:splitAt(raw1, 7)
      local s2int1, s2int2 = self:splitAt(raw2, 7)
      
      s1int1 = s1int1 / 1e7
      s2int1 = s2int1 / 1e7
      
      local RADIUS, ONE = self.RADIUS, self.RADIX_RHS_VAL
      local POW_TEN, POW_TEN_ONE = self.LOOKUP.POWERS_OF_TEN, self.LOOKUP.POWERS_OF_TEN_SCALED_ONE
      
      -- upper coefficient 10^(14 - RADIUS)
      local uc = POW_TEN[14 - RADIUS]
      -- inverse of cross coefficient 10^(7 - RADIUS)
      local icc = POW_TEN_ONE[RADIUS - 7]
      
      local p00 = s1int1 * s2int1
      p00 = (p00 == 0 or uc == ONE) and p00 or s1int1 * s2int1 * uc
      
      local p01 = s1int1 == 0 and 0 or self:div(s1int1 * s2int2, icc, policy, nil, 0)
      local p10 = s2int1 == 0 and 0 or self:div(s2int1 * s1int2, icc, policy, nil, 0)
      
      -- if upper coefficient is low, the lower coefficient is vanishingly small, making it not worth the two divides
      -- (benefit of using radius 14) 
      local p11 = uc == ONE and 0 or self:div(self:div(s1int2 * s2int2, icc, policy, true, 0), 1e7 * ONE, policy, nil, 0)
      
      return p00 + p01 + p10 + p11
   end
   
   -- division: note A9
   function FixedPoint:div(raw1, raw2, policy, ignoreOverflow, errorlevel)
      if ignoreOverflow == nil then
         ignoreOverflow = _IGNORE_OVERFLOW_DEFAULT
      end
      
      if (raw1 == 0) or (raw2 == 0) then
         return raw1 / raw2
      end
      
      policy = policy or self.ROUND_POLICY
      
      if (errorlevel or _ERRORLEVEL) > 0 then
         self:assert_valid("raw1", raw1)
         self:assert_valid("raw2", raw2)
      end
      
      local ONE = self.RADIX_RHS_VAL
      
      -- lower dividend left hand side value
      --   that is, the first number whose intermediate dividend result should produce dangerous overflow
      --   not the prescribed overflow (self.OVERFLOW_VAL), but the best possible safe choice
      local ldlhsv
      if self.LOOKUP then
         ldlhsv = self.LOOKUP.POWERS_OF_TEN[15 - self.RADIX_POINT]
      else
         ldlhsv = 1e15 / ONE
      end
         -- raw1 mod raw2, aka remainder
      local rmr, q
      
      -- fast method for small numerators
      if (abs(raw1) < ldlhsv) then
         local num = raw1 * ONE
         rmr = fmod(num, raw2)
         
         q = (num - rmr) / raw2
      else
         -- the lower numerator must be digit shifted left by RADIX_RHS_VAL, in a space of _MAX_RADIUS workable digits.
         -- we are effectively padding the lower numerator by RADIX_POINT zeroes. so the amount of usable digits remaining is as follows:
         --   _MAX_RADIUS - RADIX_POINT
         -- so to enforce that rule, retaining only the lower portion of digits, we take a modulus by its power of ten, same as ldlhsv
         --   then we pad zeroes, multiplying by RADIX_RHS_VAL.
         local numpart = fmod(raw1, ldlhsv)
         local lnum = numpart * ONE
         local unum = raw1 - numpart
         
         -- how do we do the division? simple: do a few, and sum. as in:
         --   (a+b)/c = a/c + b/c
         -- of course, the quotient from upper_num needs to be corrected
         
         local lrmr, urmr = fmod(lnum, raw2), fmod(unum, raw2)
         local urmr_scaled
         local raw2_scaled = raw2
         if (urmr < 0 and -urmr or urmr) > ldlhsv then
            -- large urmr case: note B1
            urmr_scaled = urmr * 10
            raw2_scaled = self:roundAt(raw2, self.RADIX_POINT - 1, "HALF_TO_EVEN") / self._INTERNALS.RADIX_LHS_VAL
         else
            urmr_scaled = urmr * ONE
         end
         local urmr_rmr = fmod(urmr_scaled, raw2_scaled)
         
         -- behold this behemoth!
         q = ((lnum - lrmr) / raw2) + ((unum - urmr) / raw2) * ONE + ((urmr_scaled - urmr_rmr) / raw2_scaled)
         
         -- now there's still a total remainder to consider, which is the sum lrmr + urmr_rmr. taking the sum of two remainders
         --   could affect the quotient ( consider two remainders 999 and 999 where the divisor is 1000 )
         
         if urmr > ldlhsv then
            -- inflate the rmr if the denominator was scaled down
            urmr_rmr = urmr_rmr * self._INTERNALS.RADIX_LHS_VAL
         end
         rmr = urmr_rmr + lrmr
         if (abs(rmr) >= abs(raw2)) then
            q = q < 0 and q - 1 or q + 1
            -- fmod to preserve sign
            rmr = fmod(rmr, raw2)
         end
      end
      
      if not ignoreOverflow and self:chk_overflow(q) then
         error("FixedPoint: OVERFLOW (division). op1: "..raw1.." op2: "..raw2..".")
      end
      
      rmr = abs(rmr)
      raw2 = abs(raw2 - rmr)
      
      local frac
      if rmr > raw2 then
         frac = self.CONSTANT.HALF + 1
      elseif rmr == 0 then
         frac = 0
      elseif rmr < raw2 then
         frac = 1
      else
         frac = self.CONSTANT.HALF
      end
      
      return self:lsdRound(q, q < 0 and -frac or frac, policy)
   end
   
   function FixedPoint:mod(raw1, raw2)
      return raw1 % raw2
   end
   
   function FixedPoint:fmod(raw1, raw2)
      return fmod(raw1, raw2)
   end
   
   function FixedPoint:modf(raw)
      return self:split(raw)
   end
   
   -- FixedPoint#mustEnlarge() function: note B2
   function FixedPoint:mustEnlarge(policy, int, frac, RHS_VAL)
      RHS_VAL = RHS_VAL or self.RADIX_RHS_VAL
      if frac == 0 then
         return false
      elseif type(policy) == "string" then
         policy = FixedPoint.static.ROUND_POLICY[policy] or policy
      elseif type(policy) == "function" then
         return policy(int, frac)
      end
      local half = RHS_VAL / 2
      local sign = frac >= 0 and 1 or -1
      frac = frac >= 0 and frac or -frac
      
      if policy == FixedPoint.static.ROUND_POLICY.CUSTOM then
         return self:ROUND_FN(int, frac, RHS_VAL)
      elseif policy == FixedPoint.static.ROUND_POLICY.HALF_TO_EVEN then
         if frac == half then
            if sign == -1 then
               return int % (2 * RHS_VAL) == 0
            else
               return int % (2 * RHS_VAL) == RHS_VAL
            end
         else
            return frac > half
         end
      elseif policy == FixedPoint.static.ROUND_POLICY.HALF_AWAY_FROM_ZERO then
         return frac >= half
      elseif policy == FixedPoint.static.ROUND_POLICY.HALF_TOWARDS_ZERO then
         return frac > half
      elseif policy == FixedPoint.static.ROUND_POLICY.NEXT_INT then
         return sign ~= -1
      elseif policy == FixedPoint.static.ROUND_POLICY.LAST_INT then
         return sign == -1
      elseif policy == FixedPoint.static.ROUND_POLICY.HALF_UP then
         if sign  == -1 then
            return frac < half
         else
            return frac >= half
         end
      elseif policy == FixedPoint.static.ROUND_POLICY.HALF_DOWN then
         if sign == -1 then
            return frac <= half
         else
            return frac > half
         end
      end
      
      error("FixedPoint: unknown round policy enum '" .. policy .. "'")
   end
   
   -- round takes a raw value in fixed point context, returning a value that chooses the best of two nearest values with a zero fractional part
   -- the best value depends on the choice of policy. ieee rounding is 'HALF_TO_EVEN'. a custom rounding function can be provided
   -- for values with a fractional part that is already zero, #round() is an identity
   function FixedPoint:round(raw, policy)
      assert_int("raw", raw)
   -- r1: the higher integer that may change depending on r2 (the integer part)
   -- r2: the lower integer that will ultimately determine rounded result (the fractional part)
      local r1, r2 = self:split(raw)
      
      if r2 ~= 0 and ((policy and self:mustEnlarge(policy, r1, r2)) or (not policy and self:ROUND_FN(r1, r2))) then
            return sign(raw) * (abs(r1) + self.RADIX_RHS_VAL)
      end
      
      return r1
   end
   
   -- round at a specific digit at a distance i from the least significant digit.
   -- use lsdRound to round at the least significant digit!
   function FixedPoint:roundAt(raw, i, policy)
      assert_int("raw", raw)
      assert_int("i", i)
      assert(i > 0, "FixedPoint: out of bounds, specified location i = " .. i .. " for #roundAt() must be greater than zero")
      assert(i < self.RADIUS, "FixedPoint: out of bounds, specified location i = " .. i .. " for #roundAt() is too high")
      
      local RHS_VAL = self.LOOKUP.POWERS_OF_TEN[i]
      local r1, r2
      r2 = fmod(raw, RHS_VAL)
      r1 = raw - r2
      
      if r2 ~= 0 and ((policy and self:mustEnlarge(policy, r1, r2, RHS_VAL)) or (not policy and self:ROUND_FN(r1, r2, RHS_VAL))) then
         return sign(raw) * (abs(r1) + RHS_VAL)
      end
      
      return r1
   end
   
   -- lsd: least significant digit. you need to provide a virtual / "hanging" fractional part.
   -- this rounds the prospected fractional part of the given value using a given virtual fractional part.
   -- e.g. radius 5 radix 2 fixed-point value 123.45 with virtual fraction 000.51, HALF_AWAY_FROM_ZERO policy:
   --      the value will become 123.46
   function FixedPoint:lsdRound(raw, frac, policy)
      assert_int("raw", raw)
      assert_int("frac", frac)
      if frac == 0 then
         return raw
      elseif sign(raw) ~= 0 then
         assert(sign(raw) == sign(frac), "FixedPoint: caught sign inconsistency between virtual fraction and fixed point value")
      end
      
      if (policy and self:mustEnlarge(policy, raw, frac)) or (not policy and self:ROUND_FN(raw, frac)) then
         return sign(frac) * (abs(raw) + 1)
      end
      
      return raw
   end
   
   -- you will get a readable version of the fixed point value as a string
   function FixedPoint:toString(raw)
      self:assert_valid("raw", raw)
      if abs(raw) == math.huge or raw ~= raw then
         return tostring(raw)
      end
      
      local int, frac = self:split(raw)
      
      return string.format("%s%0"..(self.RADIUS - self.RADIX_POINT).."d.%0"..self.RADIX_POINT.."d",
         raw < 0 and "-" or "", abs(int / self.RADIX_RHS_VAL), abs(frac))
   end
   
   -- you will get a readable string that describes the fixed point context in the following format:
   -- "radius (number), radix (number), default round policy (policy name)"
   function FixedPoint:describe()
      return string.format("radius %d, radix %d, default round policy %s", self.RADIUS, self.RADIX_POINT, self.ROUND_POLICY)
   end
   
   function FixedPoint:convertInt(n)
      assert_int("input int", n)
      
      n = n * self.RADIX_RHS_VAL
      self:assert_valid("converted int", n)
      
      return n
   end
   
   -- FixedPoint#genRand() function: note B3
   function FixedPoint:genRand(randfn)
      randfn = randfn or self.RAND_FN
      local rand = math.floor(randfn(self))
      -- assert(not self:chk_overflow(rand), "FixedPoint: randfn returned a value with overflow")
      
      return rand
   end
   
   -- get a random fixed point value that is bounded
   -- nil can be passed to either bound to eliminate it
   function FixedPoint:genRandInRange(randfn, rawL, rawU)
      rawL = rawL or -self.OVERFLOW_VAL + 1
      rawU = rawU or  self.OVERFLOW_VAL - 1
      
      assert_int("rawL", rawL)
      assert_int("rawU", rawU)
      if rawL > rawU then
         error("FixedPoint: larger lower bound than upper bound (lower: " .. self:toString(rawL) .. " , upper: " .. self:toString(rawU) .. ")")
      end
      
      randfn = randfn or self.RAND_FN
      local rand = math.floor(randfn(self))
      
      return rawL + (rand % ( (rawU - rawL) + 1 ))
   end
   
   -- set the default randfn to use with genRand
   -- see note B3 for the function specification
   function FixedPoint:setRandFn(randfn)
      assert(type(randfn) == "function", "FixedPoint: please provide a function value to setRandFn (got " .. type(randfn) .. ")")
      self.RAND_FN = randfn
   end
   
   -- FixedPoint#asValue() function: note B4
   function FixedPoint:asValue(int, frac6, policy)
      assert_int("int", int)
      assert_int("frac6", frac6)
      assert(math.abs(frac6) < 1e7, "FixedPoint: frac6 must contain six digits at most")
      
      return as_value(self, int, frac6, policy)
   end
   
   -- newton's method x_(N+1) = 0.5 * ( x_N + ( X / x_N ) )
   -- vary to work with fixed point
   -- x_(N+1) = HALF * ( ( x_N / one )  + ( X / x_N ) )
   function FixedPoint:sqrt(raw)
      assert_int("raw", raw)
      local ONE = self.RADIX_RHS_VAL
      if raw == 0 then
         return 0
      elseif raw == ONE then
         return ONE
      elseif raw < 0 then
         return 0/0
      end
      
      if raw >= 9e15 then
         error("FixedPoint: attempt to take sqrt of a value with dangerous overflow. op1: " .. raw)
      end
      
      local isnt_inv = raw >= self.RADIX_RHS_VAL
      
      local POWERS_ONE = self.LOOKUP.POWERS_OF_TWO_SCALED_ONE
      local POWER_LOOKUP_FTR2, POWER_LOOKUP_FR2
      if isnt_inv then
         POWER_LOOKUP_FTR2 = self.LOOKUP.POWERS_OF_TWO_SCALED_FTR2
         POWER_LOOKUP_FR2 = self.LOOKUP.POWERS_OF_TWO_SCALED_FR2
      else
         POWER_LOOKUP_FTR2 = self.LOOKUP.INV_POWERS_OF_TWO_SCALED_FTR2
         POWER_LOOKUP_FR2 = self.LOOKUP.INV_POWERS_OF_TWO_SCALED_FR2
      end
      
      -- sqrt algorithm: note B5
      local pot = POWERS_ONE[0]
      do
         local pot_next = POWERS_ONE[4]
         local half, potexp = false, 0
         local x = raw
         if not isnt_inv then
            x = self:div(ONE, raw, "HALF_TO_EVEN", true)
         end
         
         while x > pot_next do
            pot = pot_next
            potexp = potexp + 4
            pot_next = POWERS_ONE[potexp + 4] or 9e15
         end
         
         pot_next = POWERS_ONE[potexp + 1]
         
         while x > pot_next do
            pot = pot_next
            potexp = potexp + 1
            half = not half
            pot_next = POWERS_ONE[potexp + 1] or 9e15
         end
         
         if half then
            pot = POWER_LOOKUP_FTR2[(potexp - 1) / 2]
         else
            pot = POWER_LOOKUP_FR2[potexp / 2]
         end
      end
      
      local HALF = self.CONSTANT.HALF
      for i = 1, 3 do
         --pot = self:mult(HALF, self:mult(pot, 1, policy) + self:div(raw, pot, policy), policy)
         pot = self:mult(HALF, pot + self:div(raw, pot, "HALF_TO_EVEN", true), "HALF_TO_EVEN", true)
         -- dangerous overshooting prevention
         -- assign value a little smaller than sqrt(OVERFLOW_VAL) if intermediate is large enough to make overflow in square
         if pot >= self._INTERNALS.OVF_SQRT then
            pot = self._INTERNALS.OVF_SQRT - 1
         end
      end
      
      return pot
   end
   
   -- get the hypotenuse of a right triangle given two side lengths x, y
   -- from numpy, npy_hypot()
   -->>> https://github.com/numpy/numpy/blob/master/numpy/core/src/npymath/npy_math_internal.h.src
   function FixedPoint:hypot(x, y, policy, ignoreOverflow)
      assert_int("x", x)
      assert_int("y", y)
      if ignoreOverflow == nil then
         ignoreOverflow = _IGNORE_OVERFLOW_DEFAULT
      end
      local yx = 0
      local ONE = self.RADIX_RHS_VAL
      policy = policy or "HALF_TO_EVEN"
      
      x = x >= 0 and x or -x
      y = y >= 0 and y or -y
      
      if x == math.huge or y == math.huge then
         return math.huge
      elseif x ~= x or y ~= y then
         return 0/0
      end
      local result = 0
      
      if x < y then
         local temp = y
         y = x
         x = temp
      end
      
      if x == 0 then
         return 0
      else
         yx = self:div(y, x, policy)
         result = self:mult(x, self:sqrt(ONE + self:mult(yx, yx, policy)), policy)
         if not ignoreOverflow and self:chk_overflow(result) then
            error("FixedPoint: OVERFLOW (hypotenuse). op1: " .. self:toString(x) .. " op2: " .. self:toString(y))
         end
         return result
      end
   end
   
   FixedPoint.static.assert_int = assert_int
   
   -- extensions
   if game then
      for i, v in next, script:GetChildren() do
         local s, e = pcall(function()
            FixedPoint:include(require(v))
         end)
         if not s then
            warn("FixedPoint: module '" .. v.Name .. "' could not be added: " .. e)
         end
      end
   end
   for i, v in next, extpaths do
      FixedPoint:include(require(v))
   end
   
   return FixedPoint