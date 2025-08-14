"use client";

import * as React from "react";
import { format, addDays } from "date-fns";
import { Calendar as CalendarIcon } from "lucide-react";
import { DateRange } from "react-day-picker";

import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Calendar } from "@/components/ui/calendar";
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover";
import {
  Select,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from "@/components/ui/select";
import { SelectSeparator } from "@/components/ui/select";
import { useHotkeys } from "react-hotkeys-hook";

type DateRangePickerProps = {
  from: Date;
  to: Date;
};

const getDateRange = (value: string): { from: Date; to: Date } => {
  const today = new Date();
  let from, to;

  switch (value) {
    case "today":
      from = new Date(today);
      to = new Date(today);
      break;
    case "yesterday":
      from = addDays(today, -1);
      to = addDays(today, -1);
      break;
    case "last_week":
      to = today;
      from = addDays(today, -7);
      break;
    case "last_30_days":
      to = today;
      from = addDays(today, -30);
      break;
    case "last_90_days":
      to = today;
      from = addDays(today, -90);
      break;
    case "last_12_month":
      to = today;
      from = addDays(today, -365);
      break;
    case "previous_week":
      to = addDays(today, -7); // End of last week (yesterday)
      from = addDays(today, -14); // Start of last week
      break;
    case "previous_month":
      to = new Date(today.getFullYear(), today.getMonth(), 0);
      from = new Date(today.getFullYear(), today.getMonth() - 1, 1);
      break;
    case "previous_quarter":
      const currentQuarter = Math.floor(today.getMonth() / 3);
      to = new Date(today.getFullYear(), currentQuarter * 3, 0);
      from = new Date(today.getFullYear(), (currentQuarter - 1) * 3, 1);
      break;
    case "previous_year":
      to = new Date(today.getFullYear() - 1, 11, 31);
      from = new Date(today.getFullYear() - 1, 0, 1);
      break;
    case "all_time":
      from = new Date(0); // Earliest possible date
      to = today;
      break;
    default:
      from = to = today;
  }

  return { from, to };
};

export function DateRangePicker({
  dateRange,
  pushEvent,
}: {
  dateRange: DateRangePickerProps;
  pushEvent: any;
}) {
  const [date, setDate] = React.useState<DateRange | undefined>({
    from: dateRange.from,
    to: dateRange.to,
  });

  const set_selected = (value: string): void => {
    const { from, to } = getDateRange(value);

    setDate({ from, to });

    pushEvent("set_date", {
      value: {
        from: format(from, "yyyy-MM-dd 00:00:00"),
        to: format(to, "yyyy-MM-dd 23:59:59"),
      },
    });
  };

  useHotkeys("t", () => set_selected("today"), []);
  useHotkeys("ctrl+t", () => set_selected("yesterday"), []);
  useHotkeys("w", () => set_selected("last_week"), []);
  useHotkeys("m", () => set_selected("last_30_days"), []);
  useHotkeys("q", () => set_selected("last_90_days"), []);
  useHotkeys("y", () => set_selected("last_12_month"), []);
  useHotkeys("ctrl+w", () => set_selected("previous_week"), []);
  useHotkeys("ctrl+m", () => set_selected("previous_month"), []);
  useHotkeys("ctrl+q", () => set_selected("previous_quarter"), []);
  useHotkeys("ctrl+y", () => set_selected("previous_year"), []);
  useHotkeys("a", () => set_selected("all_time"), []);

  return (
    <div className={cn("grid gap-2")}>
      <Popover>
        <PopoverTrigger asChild>
          <Button
            id="date"
            variant={"outline"}
            className={cn(
              "w-[276px] justify-start text-left font-normal",
              !date && "text-muted-foreground",
            )}
          >
            <CalendarIcon className="mr-2 h-4 w-4" />
            {date?.from ? (
              date.to ? (
                <>
                  {format(date.from, "dd LLL, y")} -{" "}
                  {format(date.to, "dd LLL, y")}
                </>
              ) : (
                format(date.from, "dd LLL, y")
              )
            ) : (
              <span>Pick a date</span>
            )}
          </Button>
        </PopoverTrigger>
        <PopoverContent className="w-auto p-0" align="end">
          <Select
            onValueChange={(value) => {
              set_selected(value);
            }}
          >
            <SelectTrigger>
              <SelectValue placeholder="Select" />
            </SelectTrigger>
            <SelectContent position="popper">
              <SelectItem value="today">Today</SelectItem>
              <SelectItem value="yesterday">Yesterday</SelectItem>
              <SelectItem value="last_week">Last week</SelectItem>
              <SelectSeparator className="my-2" />
              <SelectItem value="last_30_days">Last 30 days</SelectItem>
              <SelectItem value="last_90_days">Last 90 days</SelectItem>
              <SelectItem value="last_12_month">Last 12 month</SelectItem>
              <SelectSeparator className="my-2" />
              <SelectItem value="previous_month">Previous month</SelectItem>
              <SelectItem value="previous_quarter">Previous quarter</SelectItem>
              <SelectSeparator className="my-2" />
              <SelectItem value="all_time">All time</SelectItem>
            </SelectContent>
          </Select>
          <Calendar
            initialFocus
            mode="range"
            defaultMonth={date?.from}
            selected={date}
            onSelect={(value) => {
              setDate(value);
              if (value?.from && value?.to) {
                const fromDate = format(value.from, "yyyy-MM-dd 00:00:00");
                const toDate = format(value.to, "yyyy-MM-dd 23:59:59");

                pushEvent("set_date", {
                  value: {
                    from: fromDate,
                    to: toDate,
                  },
                });
              }
            }}
            numberOfMonths={1}
          />
        </PopoverContent>
      </Popover>
    </div>
  );
}
