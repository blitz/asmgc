#include <cstdint>
#include <cstddef>

extern "C" void *c_collect(void *root_array, size_t roots,
                           void *from, void *to, size_t heap_size);

namespace {

  enum class obj_type : uint16_t {
    FRAME   = 0,
    CONS    = 1,
    STRING  = 2,
    FORWARD = 0xFFFF,
  };

  struct obj {
    uint16_t size;
    obj_type type;
    uint32_t padding;
  };

  struct frame : public obj
  {
    obj      *last_frame;
    uintptr_t link;

    size_t local_vars() const {
      return (size - sizeof(frame)) / 8;
    }
  };

  struct frame_with_local_vars : public frame
  {
    uintptr_t  pointer_bitmap;
    obj       *local_var[];
  };

  struct cons : public obj
  {
    obj      *first;
    obj      *rest;
  };

  struct forward : public obj
  {
    obj      *ptr;
  };

  void copy(obj *to, obj const *from)
  {
    size_t len = from->size;
    asm ("rep movsb"
         : "+S" (from), "+D" (to), "+c" (len), "=m" (*to)
         : "m" (*from));
  }

  /// Copies a single object into to-space or follows its forwarding pointer.
  void update_ptr(obj *&ptr, char *&alloc_start, char *alloc_end)
  {
    if (ptr == 0) {
      return;
    }

    // TODO Check whether ptr is valid and points into from space

    if (ptr->type == obj_type::FORWARD) {
      ptr = static_cast<forward *>(ptr)->ptr;
      return;
    }

    // Allocate memory in to space
    obj *to_obj = reinterpret_cast<obj *>(alloc_start);
    alloc_start += ptr->size;

    if (alloc_start > alloc_end) {
      __builtin_trap();
    }

    copy(to_obj, ptr);

    // Replace old object to forwarding pointer to this object
    ptr->type = obj_type::FORWARD;
    static_cast<forward *>(ptr)->ptr = to_obj;

    // Replace old pointer to point to new object
    ptr = to_obj;

    // Recursively copy all referenced objects.
    switch (to_obj->type) {
    case obj_type::FRAME: {
      auto   *a_frame    = static_cast<frame *>(to_obj);
      size_t  local_vars = a_frame->local_vars();
      update_ptr(a_frame->last_frame, alloc_start, alloc_end);

      for (size_t i = 0; i < local_vars; i++) {
        auto *a_frame_vars = static_cast<frame_with_local_vars *>(a_frame);
        if (a_frame_vars->pointer_bitmap & (1ULL << i)) {
          update_ptr(a_frame_vars->local_var[i], alloc_start, alloc_end);
        }
      }

      break;
    }
    case obj_type::CONS:
      update_ptr(static_cast<cons *>(to_obj)->first, alloc_start, alloc_end);
      update_ptr(static_cast<cons *>(to_obj)->rest,  alloc_start, alloc_end);
      break;
    case obj_type::STRING:
      // Nothing to do.
      break;
    default:
      __builtin_trap();
    }

    return;
  }

}

void *c_collect(void *root_array, size_t roots, void *from, void *to, size_t heap_size)
{
  auto *root_ptrs   = static_cast<obj **>(root_array);
  auto *alloc_start = static_cast<char *>(to);

  for (size_t i = 0; i < roots; i++) {
    update_ptr(root_ptrs[i], alloc_start, alloc_start + heap_size);
  }

  return alloc_start;
}
